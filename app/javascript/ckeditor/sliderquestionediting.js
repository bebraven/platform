import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import InsertSliderQuestionCommand from './insertsliderquestioncommand';

export default class SliderQuestionEditing extends Plugin {
    static get requires() {
        return [ Widget ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();

        this.editor.commands.add( 'insertSliderQuestion', new InsertSliderQuestionCommand( this.editor ) );
    }

    /**
     * Example valid structure:
     *
     * <questionFieldset>
     *   <slider/>
     *   <displayValueDiv>
     *     <currentValueSpan/>
     *     $text
     *   </displayValueDiv>
     * </questionFieldset>
     */
    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.register( 'displayValueDiv', {
            isObject: true,
            allowIn: 'questionFieldset',
            allowContentOf: [ '$block' ],
        } );

        schema.register( 'currentValueSpan', {
            isObject: true,
            allowIn: 'displayValueDiv',
        } );

        // This is inlcuded for legacy support only; we do not want to allow new ones.
        schema.register( 'sliderFeedback', {
            isObject: true,
            allowIn: [ '$root', 'tableCell' ],
            allowAttributes: [ 'data-bz-range-flr', 'data-bz-range-clg', 'aria-live' ],
            allowContentOf: [ '$block' ],
        } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;
        const { editing, data, model } = editor;

        // <displayValueDiv> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: ['display-value']
            },
            model: 'displayValueDiv'
        } );
        conversion.for( 'downcast' ).elementToElement( {
            model: 'displayValueDiv',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'div', {
                    'class': 'display-value',
                } );
            }
        } );

        // <currentValueSpan> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'span',
                classes: ['current-value']
            },
            model: 'currentValueSpan'
        } );
        conversion.for( 'downcast' ).elementToElement( {
            model: 'currentValueSpan',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEmptyElement( 'span', {
                    'class': 'current-value',
                } );
            }
        } );

        // <sliderFeedback> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: ['feedback']
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'sliderFeedback', {
                    'data-bz-range-flr': viewElement.getAttribute('data-bz-range-flr') || 0,
                    'data-bz-range-clg': viewElement.getAttribute('data-bz-range-clg') || 100,
                    'aria-live': 'polite',
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'sliderFeedback',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'div', {
                    'class': 'feedback',
                    'data-bz-range-flr': modelElement.getAttribute('data-bz-range-flr') || 0,
                    'data-bz-range-clg': modelElement.getAttribute('data-bz-range-clg') || 100,
                    'aria-live': 'polite',
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'sliderFeedback',
            view: ( modelElement, viewWriter ) => {
                const div = viewWriter.createEditableElement( 'div', {
                    'class': 'feedback',
                    'data-bz-range-flr': modelElement.getAttribute('data-bz-range-flr') || 0,
                    'data-bz-range-clg': modelElement.getAttribute('data-bz-range-clg') || 100,
                    'aria-live': 'polite',
                } );

                return toWidgetEditable( div, viewWriter );
            }
        } );

    }
}
