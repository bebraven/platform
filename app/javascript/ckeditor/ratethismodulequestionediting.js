import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { toWidget } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import InsertRateThisModuleQuestionCommand from './insertratethismodulequestioncommand';

export default class RateThisModuleQuestionEditing extends Plugin {
    static get requires() {
        return [ Widget ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();

        this.editor.commands.add( 'insertRateThisModuleQuestion', new InsertRateThisModuleQuestionCommand( this.editor ) );
    }

    /**
     * Example valid structures:
     *
     * <section>
     *   <rateThisModuleQuestion>
     *     <question>
     *       <questionTitle>$text</questionTitle>
     *       <questionForm>
     *         <questionFieldset>
     *           <legend>$text</legend>
     *           <rateThisModuleSliderContainer>
     *             <rateThisModuleSliderLabelLeft>
     *             </rateThisModuleSliderLabelLeft>
     *             <sliderInput/>
     *             <rateThisModuleSliderLabelRight>
     *             </rateThisModuleSliderLabelRight>
     *           </rateThisModuleSliderContainer>
     *           <legend>$text</legend>
     *           <textArea/>
     *         </questionFieldset>
     *       </questionForm>
     *     </question>
     *   </rateThisModuleQuestion>
     * </section>
     */
    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.register( 'rateThisModuleQuestion', {
            isObject: true,
            allowIn: 'section',
        } );

        schema.extend( 'question', {
            allowIn: 'rateThisModuleQuestion'
        } );

        schema.register( 'rateThisModuleSliderContainer', {
            isObject: true,
            allowIn: [ 'questionFieldset', '$root' ],
        } );

        schema.register( 'rateThisModuleSliderLabelLeft', {
            isInline: true,
            isLimit: true,
            allowIn: 'rateThisModuleSliderContainer',
            allowContentOf: '$block',
        } );

        schema.register( 'rateThisModuleSliderLabelRight', {
            isInline: true,
            isLimit: true,
            allowIn: 'rateThisModuleSliderContainer',
            allowContentOf: '$block',
        } );

        schema.extend( 'slider', {
            allowIn: 'rateThisModuleSliderContainer'
        } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;
        const { editing, data, model } = editor;

        // <rateThisModuleQuestion> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: ['module-block', 'module-block-rate-this-module']
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'rateThisModuleQuestion', {} );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'rateThisModuleQuestion',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'div', {
                    'class': 'module-block module-block-rate-this-module',
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'rateThisModuleQuestion',
            view: ( modelElement, viewWriter ) => {
                const rateThisModuleQuestion = viewWriter.createContainerElement( 'div', {
                    'class': 'module-block module-block-rate-this-module',
                } );

                return toWidget( rateThisModuleQuestion, viewWriter, { label: 'rate-this-module widget' } );
            }
        } );

        // <rateThisModuleSliderContainer> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'rateThisModuleSliderContainer',
            view: {
                name: 'div',
                classes: [ 'slider-container', 'range' ],
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'rateThisModuleSliderContainer',
            view: {
                name: 'div',
                classes: [ 'slider-container', 'range' ],
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'rateThisModuleSliderContainer',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'div', {
                    'class': 'slider-container range',
                } );
            }
        } );

        // <rateThisModuleSliderLabelLeft> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'rateThisModuleSliderLabelLeft',
            view: {
                name: 'span',
                classes: [ 'range-label-left' ]
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'rateThisModuleSliderLabelLeft',
            view: {
                name: 'span',
                classes: [ 'range-label-left' ]
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'rateThisModuleSliderLabelLeft',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'span', {
                    'class': 'range-label-left'
                } );
            }
        } );

        // <rateThisModuleSliderLabelRight> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'rateThisModuleSliderLabelRight',
            view: {
                name: 'span',
                classes: [ 'range-label-right' ]
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'rateThisModuleSliderLabelRight',
            view: {
                name: 'span',
                classes: [ 'range-label-right' ]
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'rateThisModuleSliderLabelRight',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'span', {
                    'class': 'range-label-right'
                } );
            }
        } );
    }
}
