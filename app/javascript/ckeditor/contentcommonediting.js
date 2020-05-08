import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { enablePlaceholder } from '@ckeditor/ckeditor5-engine/src/view/placeholder';
import { toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import List from '@ckeditor/ckeditor5-list/src/list';
import RetainedData from './retaineddata';
import InsertTextInputCommand from './inserttextinputcommand';
import InsertDoneButtonCommand from './insertdonebuttoncommand';
import InsertContentBlockCommand from './insertcontentblockcommand';
import InsertFileUploadQuestionCommand from './insertfileuploadquestioncommand';
import { ALLOWED_ATTRIBUTES, filterAllowedAttributes } from './customelementattributepreservation';

export default class ContentCommonEditing extends Plugin {
    static get requires() {
        return [ Widget, RetainedData, List ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();

        this.editor.commands.add( 'insertTextInput', new InsertTextInputCommand( this.editor ) );
        this.editor.commands.add( 'insertDoneButton', new InsertDoneButtonCommand( this.editor ) );
        this.editor.commands.add( 'insertContentBlock', new InsertContentBlockCommand( this.editor ) );
        this.editor.commands.add( 'insertFileUploadQuestion', new InsertFileUploadQuestionCommand( this.editor ) );

        // Add a shortcut to the retained data ID function.
        this._nextRetainedDataId = this.editor.plugins.get('RetainedData').getNextId;
    }

    _defineSchema() {
        const schema = this.editor.model.schema;

        // Shared elements.
        schema.register( 'content', {
            isObject: true,
            allowIn: [ 'moduleBlock' ],
            allowContentOf: '$root'
        });

        schema.register( 'contentTitle', {
            isLimit: true,
            allowIn: 'content',
            allowAttributes: [ 'id' ],
            allowContentOf: '$block'
        } );

        schema.register( 'contentBody', {
            isLimit: true,
            allowIn: 'content',
            allowContentOf: '$root'
        } );

        schema.register( 'question', {
            isObject: true,
            allowIn: [ 'moduleBlock' ],
            allowAttributes: [ 'data-instant-feedback', 'data-mastery', 'data-grade-as' ]
        } );

        schema.extend( 'paragraph', {
            allowIn: 'question'
        } );

        schema.register( 'questionTitle', {
            isLimit: true,
            allowIn: 'question',
            allowAttributes: [ 'id' ],
            allowContentOf: '$block'
        } );

        schema.register( 'questionBody', {
            isLimit: true,
            allowIn: 'question',
            allowContentOf: '$root'
        } );

        schema.register( 'questionForm', {
            // Cannot be split or left by the caret.
            isLimit: true,
            allowIn: [ 'question', 'content' ]
        } );

        schema.register( 'questionFieldset', {
            // Cannot be split or left by the caret.
            isLimit: true,
            allowIn: 'questionForm',
        } );

        schema.extend( 'listItem', {
            allowIn: 'questionFieldset',
        } );

        schema.register( 'doneButton', {
            isObject: true,
            allowIn: [ 'section', 'questionForm', 'question', 'content' ],
            allowAttributes: [ 'data-bz-retained', 'type', 'value', 'data-time-updated' ],
        } );

        schema.register( 'legend', {
            // Cannot be split or left by the caret.
            isLimit: true,
            allowIn: 'questionFieldset',
            allowContentOf: '$block'
        } );

        schema.register( 'answer', {
            isObject: true,
            allowIn: [ 'moduleBlock' ]
        } );

        schema.register( 'answerTitle', {
            isLimit: true,
            allowIn: 'answer',
            allowAttributes: [ 'id' ],
            allowContentOf: '$block'
        } );

        schema.register( 'answerText', {
            isLimit: true,
            allowIn: 'answer',
            allowContentOf: '$root'
        } );

        // Shared inputs.
        schema.register( 'textInput', {
            isObject: true,
            allowAttributes: [ 'type', 'placeholder' ].concat(ALLOWED_ATTRIBUTES),
            allowIn: [ '$root', '$block', 'tableCell', 'questionFieldset' ],
        } );

        schema.register( 'textArea', {
            isObject: true,
            allowAttributes: [ 'placeholder' ].concat(ALLOWED_ATTRIBUTES),
            allowIn: [ '$root', '$block', 'checkboxDiv', 'radioDiv', 'tableCell', 'questionFieldset' ],
        } );

        schema.register( 'fileUpload', {
            isObject: true,
            allowAttributes: [ 'type' ].concat(ALLOWED_ATTRIBUTES),
            allowIn: [ '$root', 'questionFieldset' ],
        } );

        schema.register( 'slider', {
            isObject: true,
            allowAttributes: [ 'type', 'max', 'min', 'step' ].concat(ALLOWED_ATTRIBUTES),
            allowIn: [ '$root', 'questionFieldset' ],
        } );

        schema.register( 'select', {
            isObject: true,
            allowAttributes: [ 'id', 'name' ].concat(ALLOWED_ATTRIBUTES),
            allowIn: [ '$root', 'questionFieldset' ],
        } );

        schema.register( 'selectOption', {
            isObject: true,
            allowAttributes: [ 'value', 'selected' ],
            allowIn: [ 'select' ],
            allowContentOf: '$block'
        } );

        // Custom elements.
        schema.register( 'contextNotes', {
            isInline: true,
            isObject: true,
            allowAttributes: [ 'data-placement', 'data-content' ],
            allowIn: [ '$block' ],
            allowContentOf: '$block'
        } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;
        const { editing, data, model } = editor;

        // <content> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'content',
            view: {
                name: 'div',
                classes: 'content'
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'content',
            view: {
                name: 'div',
                classes: 'content'
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'content',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'div', { class: 'content' } );
            }
        } );

        // <contentTitle> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'h5'
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'contentTitle', {
                    'id': viewElement.getAttribute('id'),
                } );
            },
            // Use high priority to overwrite heading converters defined in
            // customelementattributepreservation.js.
            converterPriority: 'high'
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'contentTitle',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'h5', {
                    'id': modelElement.getAttribute( 'id' ),
                } );
            },
            // Use high priority to overwrite heading converters defined in
            // customelementattributepreservation.js.
            converterPriority: 'high'
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'contentTitle',
            view: ( modelElement, viewWriter ) => {
                const h5 = viewWriter.createEditableElement( 'h5', {
                    'id': modelElement.getAttribute( 'id' ),
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: h5,
                    text: 'Content Title'
                } );

                return toWidgetEditable( h5, viewWriter );
            },
            // Use high priority to overwrite heading converters defined in
            // customelementattributepreservation.js.
            converterPriority: 'high'
        } );

        // <contentBody> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'contentBody',
            view: {
                name: 'div',
                classes: ['content-body']
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'contentBody',
            view: {
                name: 'div',
                classes: ['content-body']
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'contentBody',
            view: ( modelElement, viewWriter ) => {
                const div = viewWriter.createEditableElement( 'div', {
                    'class': 'content-body'
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: div,
                    text: 'Content body',
                    isDirectHost: false
                } );

                return toWidgetEditable( div, viewWriter );
            }
        } );

        // <question> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: 'question'
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'question', {
                    'data-instant-feedback': viewElement.getAttribute('data-instant-feedback') || false,
                    'data-mastery': viewElement.getAttribute('data-mastery') || false,
                    'data-grade-as': viewElement.getAttribute('data-grade-as') || undefined,
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'question',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'div', {
                    'class': 'question',
                    'data-instant-feedback': modelElement.getAttribute('data-instant-feedback') || false,
                    'data-mastery': modelElement.getAttribute('data-mastery') || false,
                    'data-grade-as': modelElement.getAttribute('data-grade-as') || undefined,
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'question',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'div', {
                    'class': 'question',
                    'data-instant-feedback': modelElement.getAttribute('data-instant-feedback') || false,
                    'data-mastery': modelElement.getAttribute('data-mastery') || false,
                    'data-grade-as': modelElement.getAttribute('data-grade-as') || undefined,
                } );
            }
        } );

        // <questionTitle> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'h5'
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'questionTitle', {
                    'id': viewElement.getAttribute('id'),
                } );
            },
            // Use high priority to overwrite heading converters defined in
            // customelementattributepreservation.js.
            converterPriority: 'high'
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'questionTitle',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'h5', {
                    'id': modelElement.getAttribute( 'id' ),
                } );
            },
            // Use high priority to overwrite heading converters defined in
            // customelementattributepreservation.js.
            converterPriority: 'high'
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'questionTitle',
            view: ( modelElement, viewWriter ) => {
                const h5 = viewWriter.createEditableElement( 'h5', {
                    'id': modelElement.getAttribute( 'id' ),
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: h5,
                    text: 'Question Title'
                } );

                return toWidgetEditable( h5, viewWriter );
            },
            // Use high priority to overwrite heading converters defined in
            // customelementattributepreservation.js.
            converterPriority: 'high'
        } );

        // <questionBody> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'questionBody',
            view: {
                name: 'div',
            },
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'questionBody',
            view: {
                name: 'div',
                classes: [ 'question-body' ],
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'questionBody',
            view: ( modelElement, viewWriter ) => {
                const div = viewWriter.createEditableElement( 'div', {} );

                enablePlaceholder( {
                    view: editing.view,
                    element: div,
                    text: 'Question body',
                    isDirectHost: false
                } );

                return toWidgetEditable( div, viewWriter );
            }
        } );

        // <questionForm> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'questionForm',
            view: {
                name: 'form'
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'questionForm',
            view: {
                name: 'form'
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'questionForm',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'form' );
            }
        } );

        // <questionFieldset> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'fieldset'
            },
            model: ( viewElement, modelWriter ) => {
                // Only include the class attribute if it's set.
                const classes = viewElement.getAttribute('class');
                const attrs = classes ? { 'class': classes } : {};
                return modelWriter.createElement( 'questionFieldset', attrs );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'questionFieldset',
            view: ( modelElement, viewWriter ) => {
                // Only include the class attribute if it's set.
                const classes = modelElement.getAttribute('class');
                const attrs = classes ? { 'class': classes } : {};
                return viewWriter.createEditableElement( 'fieldset', attrs );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'questionFieldset',
            view: ( modelElement, viewWriter ) => {
                // Only include the class attribute if it's set.
                const classes = modelElement.getAttribute('class');
                const attrs = classes ? { 'class': classes } : {};
                return viewWriter.createContainerElement( 'fieldset', attrs );
            }
        } );

        // <doneButton> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'input',
                classes: 'done-button',
                attributes: {
                    'type': 'button',
                    'value': 'Done',
                }
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'doneButton', {
                    'data-bz-retained': viewElement.getAttribute('data-bz-retained') || this._nextRetainedDataId(),
                    'data-time-updated': viewElement.getAttribute('data-time-updated') || '',
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'doneButton',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEmptyElement( 'input', {
                    'type': 'button',
                    'value': 'Done',
                    'class': 'done-button',
                    'data-bz-retained': modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId(),
                    'data-time-updated': modelElement.getAttribute('data-time-updated') || '',
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'doneButton',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEmptyElement( 'input', {
                    'type': 'button',
                    'value': 'Done',
                    'class': 'done-button',
                    'data-bz-retained': modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId(),
                    'data-time-updated': modelElement.getAttribute('data-time-updated') || '',
                } );
            }
        } );

        // <questionLegend> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'legend',
            view: {
                name: 'legend'
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'legend',
            view: {
                name: 'legend'
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'legend',
            view: ( modelElement, viewWriter ) => {
                const legend = viewWriter.createEditableElement( 'legend' );

                enablePlaceholder( {
                    view: editing.view,
                    element: legend,
                    text: 'Legend'
                } );

                return toWidgetEditable( legend, viewWriter );
            }
        } );

        // <answer> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'answer',
            view: {
                name: 'div',
                classes: 'answer'
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'answer',
            view: {
                name: 'div',
                classes: 'answer'
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'answer',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'div', { class: 'answer' } );
            }
        } );

        // <answerTitle> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'h5'
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'answerTitle', {
                    'id': viewElement.getAttribute('id'),
                } );
            },
            // Use high priority to overwrite heading converters defined in
            // customelementattributepreservation.js.
            converterPriority: 'high'
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'answerTitle',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'h5', {
                    'id': modelElement.getAttribute( 'id' ),
                } );
            },
            // Use high priority to overwrite heading converters defined in
            // customelementattributepreservation.js.
            converterPriority: 'high'
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'answerTitle',
            view: ( modelElement, viewWriter ) => {
                const h5 = viewWriter.createEditableElement( 'h5', {
                    'id': modelElement.getAttribute( 'id' ),
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: h5,
                    text: 'Answer Title'
                } );

                return toWidgetEditable( h5, viewWriter );
            },
            // Use high priority to overwrite heading converters defined in
            // customelementattributepreservation.js.
            converterPriority: 'high'
        } );

        // <answerText> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'answerText',
            view: {
                name: 'div',
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'answerText',
            view: {
                name: 'div',
                classes: [ 'answer-body' ],
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'answerText',
            view: ( modelElement, viewWriter ) => {
                const div = viewWriter.createEditableElement( 'div', {} );

                enablePlaceholder( {
                    view: editing.view,
                    element: div,
                    text: 'Answer body',
                    isDirectHost: false
                } );

                return toWidgetEditable( div, viewWriter );
            }
        } );

        // Misc elements

        // <textInput> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'input',
                attributes: {
                    'type': 'text'
                }
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'textInput', new Map( [
                    ...filterAllowedAttributes(viewElement.getAttributes()),
                    ['data-bz-retained', viewElement.getAttribute('data-bz-retained') || this._nextRetainedDataId()],
                    ['placeholder', viewElement.getAttribute('placeholder') || ''],
                ] ) );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'textInput',
            view: ( modelElement, viewWriter ) => {
                const input = viewWriter.createEmptyElement( 'input', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'type', 'text' ],
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'placeholder', modelElement.getAttribute('placeholder') || '' ],
                ] ) );
                return input;
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'textInput',
            view: ( modelElement, viewWriter ) => {
                const input = viewWriter.createEmptyElement( 'input', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'type', 'text' ],
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'placeholder', modelElement.getAttribute('placeholder') || '' ],
                ] ) );
                return toWidget( input, viewWriter );
            }
        } );

        // <textArea> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'textarea',
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'textArea', new Map( [
                    ...filterAllowedAttributes(viewElement.getAttributes()),
                    [ 'data-bz-retained', viewElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'placeholder', viewElement.getAttribute('placeholder') || '' ],
                ] ) );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'textArea',
            view: ( modelElement, viewWriter ) => {
                const textarea = viewWriter.createEmptyElement( 'textarea', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'placeholder', modelElement.getAttribute('placeholder') || '' ],
                ] ) );
                return textarea;
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'textArea',
            view: ( modelElement, viewWriter ) => {
                const textarea = viewWriter.createEmptyElement( 'textarea', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'placeholder', modelElement.getAttribute('placeholder') || '' ],
                ] ) );
                return toWidget( textarea, viewWriter );
            }
        } );

        // <fileUpload> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'input',
                attributes: {
                    'type': 'file',
                }
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'fileUpload', new Map( [
                    ...filterAllowedAttributes(viewElement.getAttributes()),
                    [ 'data-bz-retained', viewElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                ] ) );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'fileUpload',
            view: ( modelElement, viewWriter ) => {
                const input = viewWriter.createEmptyElement( 'input', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'type', 'file' ],
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                ] ) );
                return input;
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'fileUpload',
            view: ( modelElement, viewWriter ) => {
                const input = viewWriter.createEmptyElement( 'input', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'type', 'file' ],
                    [ 'disabled', '' ],
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                ] ) );
                return toWidget( input, viewWriter );
            }
        } );

        // <slider> converters
        const sliderMin = 0;
        const sliderMax = 10;
        const sliderStep = 1;
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'input',
                attributes: {
                    'type': 'range',
                }
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'slider', new Map( [
                    ...filterAllowedAttributes(viewElement.getAttributes()),
                    [ 'data-bz-retained', viewElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'min', viewElement.getAttribute('min') || sliderMin ],
                    [ 'max', viewElement.getAttribute('max') || sliderMax ],
                    [ 'step', viewElement.getAttribute('step') || sliderStep ],
                ] ) );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'slider',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEmptyElement( 'input', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'type', 'range' ],
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'min', modelElement.getAttribute('min') || sliderMin ],
                    [ 'max', modelElement.getAttribute('max') || sliderMax ],
                    [ 'step', modelElement.getAttribute('step') || sliderStep ],
                ] ) );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'slider',
            view: ( modelElement, viewWriter ) => {
                const input = viewWriter.createEmptyElement( 'input', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'type', 'range' ],
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'min', modelElement.getAttribute('min') || sliderMin ],
                    [ 'max', modelElement.getAttribute('max') || sliderMax ],
                    [ 'step', modelElement.getAttribute('step') || sliderStep ],
                ] ) );
                return toWidget( input, viewWriter );
            }
        } );

        // <select> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'select',
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'select', new Map( [
                    ...filterAllowedAttributes(viewElement.getAttributes()),
                    [ 'data-bz-retained', viewElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'name', viewElement.getAttribute('name') ],
                    [ 'id', viewElement.getAttribute('id') ],
                ] ) );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'select',
            view: ( modelElement, viewWriter ) => {
                const select = viewWriter.createContainerElement( 'select', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'name', modelElement.getAttribute('name') ],
                    [ 'id', modelElement.getAttribute('id') ],
                ] ) );
                return select;
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'select',
            view: ( modelElement, viewWriter ) => {
                const select = viewWriter.createContainerElement( 'select', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'data-bz-retained', modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId() ],
                    [ 'name', modelElement.getAttribute('name') ],
                    [ 'id', modelElement.getAttribute('id') ],
                ] ) );
                return toWidget( select, viewWriter );
            }
        } );

        // <selectOption> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'option',
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'selectOption', {
                    'value': viewElement.getAttribute('value'),
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'selectOption',
            view: ( modelElement, viewWriter ) => {
                const option = viewWriter.createContainerElement( 'option', {
                    'value': modelElement.getAttribute('value'),
                } );
                return option;
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'selectOption',
            view: ( modelElement, viewWriter ) => {
                const option = viewWriter.createContainerElement( 'option', {
                    'value': modelElement.getAttribute('value'),
                } );
                return toWidget( option, viewWriter );
            }
        } );

        // Custom elements.

        // <contextNotes> converters.
        // Used by resume snippets.
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'span',
                classes: [ 'context-notes' ],
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'contextNotes', {
                    'data-content': viewElement.getAttribute('data-content'),
                    'data-placement': viewElement.getAttribute('data-placement'),
                } );
            }
        } );
        conversion.for( 'downcast' ).elementToElement( {
            model: 'selectOption',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'option', {
                    'class': 'context-notes',
                    'data-content': modelElement.getAttribute('data-content'),
                    'data-placement': modelElement.getAttribute('data-placement'),
                } );
            }
        } );


        // Shared attribute converters.
        // We must explicitly define an attributeToAttribute converter in order to live-update
        // model changes in the editingView when changing it from the setAttributes command.
        // This is because elementToElement is only called once when the element is inserted,
        // NOT when attributes are changed/added/removed.
        // See https://github.com/ckeditor/ckeditor5/issues/6308#issuecomment-590243325
        // and https://ckeditor.com/docs/ckeditor5/latest/api/module_engine_conversion_conversion-Conversion.html#function-attributeToAttribute
        conversion.attributeToAttribute( { model: 'data-correctness', view: 'data-correctness' } );
        conversion.attributeToAttribute( { model: 'placeholder', view: 'placeholder' } );
        conversion.attributeToAttribute( { model: 'src', view: 'src' } );
    }
}
