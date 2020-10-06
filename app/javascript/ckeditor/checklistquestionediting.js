import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { enablePlaceholder } from '@ckeditor/ckeditor5-engine/src/view/placeholder';
import { toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import RetainedData from './retaineddata';
import InsertChecklistQuestionCommand from './insertchecklistquestioncommand';
import InsertCheckboxCommand from './insertcheckboxcommand';
import InsertChecklistOtherCommand from './insertchecklistothercommand';
import { ALLOWED_ATTRIBUTES, filterAllowedAttributes } from './customelementattributepreservation';

export default class ChecklistQuestionEditing extends Plugin {
    static get requires() {
        return [ Widget, RetainedData ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();

        this.editor.commands.add( 'insertChecklistQuestion', new InsertChecklistQuestionCommand( this.editor ) );
        this.editor.commands.add( 'insertCheckbox', new InsertCheckboxCommand( this.editor ) );
        this.editor.commands.add( 'insertChecklistOther', new InsertChecklistOtherCommand( this.editor ) );

        // Add a shortcut to the retained data ID function.
        this._nextRetainedDataId = this.editor.plugins.get('RetainedData').getNextId;

        // Listen for 'delete' events (includes Backspace).
        this.listenTo( this.editor.editing.view.document, 'delete', ( evt, data ) => {
            data.preventDefault();
            evt.stop();
        } );

        // Pressing 'Enter' with a checkbox  selected or with the cursor in the label will insert a new one below it.
        // Because Widget._onKeydown consumes 'Enter' events for non-inline block widgets, we intercept the
        // 'keydown' event and run the insertion code immediately in our handler.
        // https://github.com/ckeditor/ckeditor5-widget/blob/bdeec63534d11a4fa682bb34990c698435bc13e3/src/widget.js#L174
        // https://github.com/ckeditor/ckeditor5-widget/blob/bdeec63534d11a4fa682bb34990c698435bc13e3/src/widget.js#L408
        this.listenTo( this.editor.editing.view.document, 'keydown', ( evt, data ) => {
            if ( data.domEvent.key !== 'Enter' ) {
                return; // Ignore non-'Enter' keys
            }

            const selection = this.editor.model.document.selection;
            const selectedElement = selection.getSelectedElement();
            const positionParent = selection.getLastPosition().parent;

            if ( ( selectedElement && selectedElement.name === 'checkboxDiv' )
                || ( positionParent && positionParent.name === 'checkboxLabel' ) ) {
                // We execute the insertion code directly rather than firing another 'Enter' event
                // to prevent CKE handlers that also listen to the event from running
                this.editor.execute( 'insertCheckbox' );
                data.preventDefault();
                evt.stop();
            }
        // Use 'highest' priority, because Widget._onKeydown listens at 'high'.
        // https://github.com/ckeditor/ckeditor5-widget/blob/bdeec63534d11a4fa682bb34990c698435bc13e3/src/widget.js#L92
        }, { priority: 'highest' } );
    }

    /**
     * Example valid structure:
     *
     * <questionFieldset>
     *   <checkboxDiv>
     *     <checkboxInput/>
     *     <checkboxLabel>$text</checkboxLabel>
     *     <checkboxInlineFeedback>$text</checkboxInlineFeedback>
     *   </checkboxDiv>
     * </questionFieldset>
     */
    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.register( 'checkboxDiv', {
            isObject: true,
            allowIn: [ 'questionFieldset' ],
        } );

        schema.register( 'checkboxInput', {
            isInline: true,
            isObject: true,
            allowIn: [ 'checkboxDiv', 'tableCell', '$root' ],
            allowAttributes: [ 'id', 'name', 'value', 'data-correctness' ].concat(ALLOWED_ATTRIBUTES),
        } );

        schema.register( 'checkboxLabel', {
            isObject: true,
            isInline: true,
            allowIn: 'checkboxDiv',
            allowContentOf: '$block',
            allowAttributes: [ 'for' ]
        } );

        schema.register( 'textareaLabel', {
            isObject: true,
            isInline: true,
            allowIn: 'checkboxDiv',
            allowContentOf: '$block',
            allowAttributes: [ 'id' ]
        } );

        schema.register( 'checkboxInlineFeedback', {
            isObject: true,
            allowIn: 'checkboxDiv',
            allowContentOf: '$block'
        } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;
        const { editing, data, model } = editor;

        // <checkboxDiv> converters
        conversion.for( 'upcast' ).elementToElement( {
            model: 'checkboxDiv',
            view: {
                name: 'div',
                classes: ['module-checkbox-div']
            }

        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'checkboxDiv',
            view: {
                name: 'div',
                classes: ['module-checkbox-div']
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'checkboxDiv',
            view: ( modelElement, viewWriter ) => {
                const div = viewWriter.createContainerElement( 'div', {
                    'class': 'module-checkbox-div'
                } );

                return toWidget( div, viewWriter, { label: 'checklist option widget' } );
            }
        } );

        // <checkboxInput> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'input',
                attributes: {
                    type: 'checkbox'
                }
            },
            model: ( viewElement, modelWriter ) => {
                const id = viewElement.getAttribute('data-bz-retained') || this._nextRetainedDataId();

                return modelWriter.createElement( 'checkboxInput', new Map( [
                    ...filterAllowedAttributes(viewElement.getAttributes()),
                    [ 'id', id ],
                    [ 'data-bz-retained', id ],
                    [ 'data-correctness', viewElement.getAttribute('data-correctness') || '' ]
                ] ) );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'checkboxInput',
            view: ( modelElement, viewWriter ) => {
                const id = modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId();

                return viewWriter.createEmptyElement( 'input', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'type', 'checkbox' ],
                    [ 'id', id ],
                    [ 'data-bz-retained', id ],
                    [ 'data-correctness', modelElement.getAttribute('data-correctness') || '' ]
                ] ) );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'checkboxInput',
            view: ( modelElement, viewWriter ) => {
                const id = modelElement.getAttribute('data-bz-retained') || this._nextRetainedDataId();

                return viewWriter.createEmptyElement( 'input', new Map( [
                    ...filterAllowedAttributes(modelElement.getAttributes()),
                    [ 'type', 'checkbox' ],
                    [ 'id', id ],
                    [ 'data-bz-retained', id ],
                    [ 'data-correctness', modelElement.getAttribute('data-correctness') || '' ],
                    [ 'disabled', 'disabled' ],
                ] ) );

                return input;
            }
        } );

        // <checkboxLabel> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'label'
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'checkboxLabel', {
                    // HACK: Get the id of the checkbox this label corresponds to.
                    'for': viewElement.parent.getChild(0).getAttribute('id')
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'checkboxLabel',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'label', {
                    'for': modelElement.parent.getChild(0).getAttribute('id')
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'checkboxLabel',
            view: ( modelElement, viewWriter ) => {
                const label = viewWriter.createEditableElement( 'label', {
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: label,
                    text: 'Answer text'
                } );

                return toWidgetEditable( label, viewWriter );
            }
        } );


         // <textareaLabel> converters
         conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: ['text-area-label', 'sr-only']
            },
            model: ( viewElement, modelWriter ) => {
                const id = viewElement.getAttribute('id') || this._nextRetainedDataId();
                return modelWriter.createElement( 'textareaLabel', {
                    'id': id,
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'textareaLabel',
            view: ( modelElement, viewWriter ) => {
                const id = modelElement.getAttribute('id') || this._nextRetainedDataId();

                return viewWriter.createEditableElement( 'div', {
                    'id': id,
                    'class': 'sr-only text-area-label'
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'textareaLabel',
            view: ( modelElement, viewWriter ) => {
                const id = modelElement.getAttribute('id') || this._nextRetainedDataId();
                const label = viewWriter.createEditableElement( 'div', {
                    'id': id,
                    'class': 'sr-only text-area-label'
                } );

                

                enablePlaceholder( {
                    view: editing.view,
                    element: label,
                    text: 'Answer text'
                } );

                return toWidgetEditable( label, viewWriter );
            }
        } );

        // <checkboxInlineFeedback> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'p',
                classes: ['inline', 'feedback']
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'checkboxInlineFeedback' );
            }

        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'checkboxInlineFeedback',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'p', {
                    'class': 'feedback inline',
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'checkboxInlineFeedback',
            view: ( modelElement, viewWriter ) => {
                const p = viewWriter.createEditableElement( 'p', {
                    'class': 'feedback inline',
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: p,
                    text: 'Inline feedback (optional)'
                } );

                return toWidgetEditable( p, viewWriter );
            }
        } );
    }
}
