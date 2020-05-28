// See https://ckeditor.com/docs/ckeditor5/latest/framework/guides/deep-dive/conversion/conversion-preserving-custom-content.html#adding-extra-attributes-to-elements-contained-in-a-figure
// and https://github.com/ckeditor/ckeditor5/issues/5569
import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import RetainedData from './retaineddata';

export const ALLOWED_ATTRIBUTES = [
    'class',
    'id',
    'data-bz-retained',
    'data-bz-weight',
    'data-bz-partial-credit',
    'data-bz-answer',
    'data-bz-dont-mix',
    'data-bz-range-answer',
    'data-bz-insert-offset-year',
    'data-bz-max-score',
    'data-bz-optional-magic-field',
    'data-bz-range-clg',
    'data-bz-range-flr',
    'data-bz-reference',
    'data-bz-share-release',
    'data-content',
    'data-placement',
    'data-original-title',
    'data-target',
    'data-toggle',
    'title',
    'tabindex',
    'style',
    'align',
];

export default class CustomElementAttributePreservation extends Plugin {
    static get requires() {
        return [ RetainedData ];
    }

    init() {
        const editor = this.editor;

        // Enable custom attributes on several predefined elements (see function).
        this._setupAllowedAttributePreservation();

        // Enable custom class on tables, within figures.
        setupCustomFigureClassConversion( 'table', 'table', editor );
        
        editor.conversion.for( 'upcast' ).add( upcastCustomClasses( 'figure' ), { priority: 'low' } );

        // Enable link extensions.
        allowLinkClass( editor );
        allowLinkRetainedData( editor );

        // Set up shortcut to get unique id
        this._nextId = editor.plugins.get('RetainedData').getNextCount;
    }

    // From https://ckeditor.com/docs/ckeditor5/latest/framework/guides/deep-dive/conversion/conversion-preserving-custom-content.html#loading-content-with-all-attributes
    _setupAllowedAttributePreservation() {
        const editor = this.editor;

        // Allow <div> elements in the model.
        editor.model.schema.register( 'div', {
            allowWhere: '$block',
            allowIn: [ 'questionFieldset', 'checkboxDiv' ],
            allowContentOf: '$root'
        } );

        // Allow <span> elements in the model.
        editor.model.schema.register( 'span', {
            isInline: true,
            allowWhere: '$block',
            allowIn: '$block',
            allowContentOf: '$block'
        } );

        // Elements we want to allow custom attribute preservation on.
        // { view: model }
        // Note: hN = heading(N-1) is a ckeditor5 convention.
        // We can do all these with normal priority because the ones we define in ContentEditor.js
        // in the CKE heading options are set to `low` priority.
        const elements = {
            'h2': 'heading1',
            'h3': 'heading2',
            'h4': 'heading3',
            'h5': 'heading4',
            'h6': 'heading5',
        }

        Object.keys( elements ).forEach( ( key ) => {
            // View-to-model converter converting a view element with all its attributes to the model.
            editor.conversion.for( 'upcast' ).elementToElement( {
                view: key,
                model: ( viewElement, modelWriter ) => {
                    let attributes = filterAllowedAttributes( viewElement.getAttributes() );
                    if ( attributes.get( 'id' ) ) {
                        attributes.set( 'toc-link-href', '#' + attributes.get( 'id' ) );
                    }
                    return modelWriter.createElement( elements[key], attributes );
                },
            } );

            editor.conversion.for( 'downcast' ).elementToElement( {
                model: elements[key], 
                view: ( modelElement, viewWriter ) => {
                    let attributes = filterAllowedAttributes( modelElement.getAttributes() );
                    if ( !attributes.get( 'id' ) ) {
                        attributes.set( 'id', this._nextId() );
                    }
                    return viewWriter.createContainerElement( key, attributes );
                },
            });

            // Table of contents converter for headings
            editor.conversion.for( 'upcast' ).add( dispatcher => {
                dispatcher.on( 'element:' + key, ( evt, data, conversionApi ) => {
                    const { schema, writer } = conversionApi;

                    if (!data.modelRange) {
                        return;
                    }
                    
                    for ( const item of data.modelRange.getItems( { shallow: true } ) ) {
                        const href = item.getAttribute('toc-link-href');
                        for ( const child of item.getChildren() ) {
                            if ( child.is( 'text' ) ) {
                                writer.setAttribute( 'linkHref', href, child);
                                return;
                            }
                        }
                    }
                } );
            } );
        } );

        // Paragraph and converter must be high priority so it overrides the CKE builtin converters.
        editor.conversion.for( 'upcast' ).elementToElement( {
            view: 'p',
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'paragraph', filterAllowedAttributes( viewElement.getAttributes() ) );
            },
            // Use high priority because the 'low' we defined for the cke paragraph converter in ContentEditor.js doesn't
            // work for some reason.
            converterPriority: 'high'
        } );
        editor.conversion.for( 'upcast' ).elementToElement( {
            view: 'td',
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'tableCell', filterAllowedAttributes( viewElement.getAttributes() ) );
            },
            // Use low priority to make sure existing converters run first.
            converterPriority: 'high'
        } );

        // Div and span converters must be normal priority or lower so they don't override more specific converters defined elsewhere.
        editor.conversion.for( 'upcast' ).elementToElement( {
            view: 'div',
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'div', filterAllowedAttributes( viewElement.getAttributes() ) );
            },
        } );
        editor.conversion.for( 'upcast' ).elementToElement( {
            view: 'span',
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'span', filterAllowedAttributes( viewElement.getAttributes() ) );
            },
            // Use low priority to make sure existing converters run first.
            converterPriority: 'low'
        } );

        // Model-to-view converter for the <div> element (attrbiutes are converted separately).
        editor.conversion.for( 'downcast' ).elementToElement( {
            model: 'div',
            view: 'div'
        } );

        // Model-to-view converter for the <span> element (attrbiutes are converted separately).
        editor.conversion.for( 'downcast' ).elementToElement( {
            model: 'span',
            view: 'span'
        } );

        // Model-to-view converter for all element attributes.
        // Note that a lower-level, event-based API is used here.
        editor.conversion.for( 'downcast' ).add( dispatcher => {
            dispatcher.on( 'attribute', ( evt, data, conversionApi ) => {
                // Allow all elements in the model to have any of a preset list of attributes.
                if ( ! ALLOWED_ATTRIBUTES.includes( data.attributeKey ) ) {
                    return;
                }

                const viewWriter = conversionApi.writer;
                const viewElement = conversionApi.mapper.toViewElement( data.item );

                // In the model-to-view conversion we convert changes.
                // An attribute can be added or removed or changed.
                // The below code handles all 3 cases.
                if ( data.attributeNewValue ) {
                    viewWriter.setAttribute( data.attributeKey, data.attributeNewValue, viewElement );
                } else {
                    viewWriter.removeAttribute( data.attributeKey, viewElement );
                }
            } );
        } );
    }
}

/**
 * Sets up a conversion that preservers classes on <img> and <table> elements.
 */
function setupCustomFigureClassConversion( viewElementName, modelElementName, editor ) {
    // The 'customClass' attribute will store custom classes from the data in the model so schema definitions allow this attribute.
    editor.model.schema.extend( modelElementName, { allowAttributes: [ 'customClass' ] } );

    // Define upcast converters for the <img> and <table> elements with a "low" priority so they are run after the default converters.
    editor.conversion.for( 'upcast' ).add( upcastCustomClasses( viewElementName ), { priority: 'low' } );

    // Define downcast converters for a model element with a "low" priority so they are run after the default converters.
    editor.conversion.for( 'downcast' ).add( downcastCustomClasses( modelElementName, viewElementName ), { priority: 'low' } );
}

/**
 * Creates an upcast converter that will pass all classes from the view element to the model element.
 */
function upcastCustomClasses( elementName ) {
    return dispatcher => dispatcher.on( `element:${ elementName }`, ( evt, data, conversionApi ) => {
        const viewItem = data.viewItem;
        const modelRange = data.modelRange;

        const modelElement = modelRange && modelRange.start.nodeAfter;

        if ( !modelElement ) {
            return;
        }

        // The upcast conversion picks up classes from the base element and from the <figure> element so it should be extensible.
        const currentAttributeValue = modelElement.getAttribute( 'customClass' ) || [];

        currentAttributeValue.push( ...viewItem.getClassNames() );

        conversionApi.writer.setAttribute( 'customClass', currentAttributeValue, modelElement );
    } );
}

/**
 * Creates a downcast converter that adds classes defined in the `customClass` attribute to a given view element.
 *
 * This converter expects that the view element is nested in a <figure> element.
 */
function downcastCustomClasses( modelElementName, viewElementName  ) {
    return dispatcher => dispatcher.on( `insert:${ modelElementName }`, ( evt, data, conversionApi ) => {
        const modelElement = data.item;

        const viewFigure = conversionApi.mapper.toViewElement( modelElement );

        if ( !viewFigure ) {
            return;
        }

        // The code below assumes that classes are set on the <figure> element...
        // conversionApi.writer.addClass( modelElement.getAttribute( 'customClass' ), viewFigure );

        // ... but if you prefer the classes to be passed to the <img> element, find the view element inside the <figure>:

        const viewElement = findViewChild( viewFigure, viewElementName, conversionApi );

        conversionApi.writer.addClass( modelElement.getAttribute( 'customClass' ), viewElement );
    } );
}

/**
 * Helper method that searches for a given view element in all children of the model element.
 *
 * @param {module:engine/view/item~Item} viewElement
 * @param {String} viewElementName
 * @param {module:engine/conversion/downcastdispatcher~DowncastConversionApi} conversionApi
 * @return {module:engine/view/item~Item}
 */
function findViewChild( viewElement, viewElementName, conversionApi ) {
    const viewChildren = Array.from( conversionApi.writer.createRangeIn( viewElement ).getItems() );

    return viewChildren.find( item => item.is( viewElementName ) );
}

/**
 * Returns the custom attribute upcast converter.
*/
function upcastAttribute( viewElementName, viewAttribute, modelAttribute ) {
    return dispatcher => dispatcher.on( `element:${ viewElementName }`, ( evt, data, conversionApi ) => {
        const viewItem = data.viewItem;
        const modelRange = data.modelRange;

        const modelElement = modelRange && modelRange.start.nodeAfter;

        if ( !modelElement ) {
            return;
        }

        conversionApi.writer.setAttribute( modelAttribute, viewItem.getAttribute( viewAttribute ), modelElement );
    } );
}

/**
 * Returns the custom attribute downcast converter.
*/
function downcastAttribute( modelElementName, viewElementName, viewAttribute, modelAttribute ) {
    return dispatcher => dispatcher.on( `insert:${ modelElementName }`, ( evt, data, conversionApi ) => {
        const modelElement = data.item;

        const viewFigure = conversionApi.mapper.toViewElement( modelElement );
        const viewElement = findViewChild( viewFigure, viewElementName, conversionApi );

        if ( !viewElement ) {
            return;
        }

        conversionApi.writer.setAttribute( viewAttribute, modelElement.getAttribute( modelAttribute ), viewElement );
    } );
}



// Filter out attributes that aren't in ALLOWED_ATTRIBUTES.
// Return a map of key:value pairs as expected by createElement.
export function filterAllowedAttributes( attributeGenerator ) {
    return new Map( [...attributeGenerator].filter( item => {
        // item == [key, value]
        return ALLOWED_ATTRIBUTES.includes( item[0] );
    } ) );
}

// From https://ckeditor.com/docs/ckeditor5/latest/framework/guides/deep-dive/conversion/conversion-preserving-custom-content.html#loading-content-with-a-custom-attribute
function allowLinkClass( editor ) {
    // Allow the "linkClass" attribute in the editor model.
    editor.model.schema.extend( '$text', { allowAttributes: 'linkClass' } );

    // Tell the editor that the model "linkClass" attribute converts into <a class="..."></a>
    editor.conversion.for( 'downcast' ).attributeToElement( {
        model: 'linkClass',
        view: ( attributeValue, writer ) => {
            const linkElement = writer.createAttributeElement( 'a', { 'class': attributeValue }, { priority: 5 } );
            writer.setCustomProperty( 'link', true, linkElement );

            return linkElement;
        },
        converterPriority: 'low'
    } );

    // Tell the editor that <a class="..."></a> converts into the "linkClass" attribute in the model.
    editor.conversion.for( 'upcast' ).attributeToAttribute( {
        view: {
            name: 'a',
            key: 'class'
        },
        model: 'linkClass',
        converterPriority: 'low'
    } );
}

function allowLinkRetainedData( editor ) {
    // Allow the "linkRetainedData" attribute in the editor model.
    editor.model.schema.extend( '$text', { allowAttributes: 'linkRetainedData' } );

    // Tell the editor that the model "linkRetainedData" attribute converts into <a data-bz-retained="..."></a>
    editor.conversion.for( 'downcast' ).attributeToElement( {
        model: 'linkRetainedData',
        view: ( attributeValue, writer ) => {
            const linkElement = writer.createAttributeElement( 'a', { 'data-bz-retained': attributeValue }, { priority: 5 } );
            writer.setCustomProperty( 'link', true, linkElement );

            return linkElement;
        },
        converterPriority: 'low'
    } );

    // Tell the editor that <a data-bz-retained="..."></a> converts into the "linkRetainedData" attribute in the model.
    editor.conversion.for( 'upcast' ).attributeToAttribute( {
        view: {
            name: 'a',
            key: 'data-bz-retained'
        },
        model: 'linkRetainedData',
        converterPriority: 'low'
    } );
}
