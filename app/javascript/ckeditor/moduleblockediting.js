import Clipboard from '@ckeditor/ckeditor5-clipboard/src/clipboard';

import Plugin from '@ckeditor/ckeditor5-core/src/plugin';

import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import { toWidget } from '@ckeditor/ckeditor5-widget/src/utils';

export default class ModuleBlockEditing extends Plugin {
    static get requires() {
        return [ Widget, Clipboard ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();

        // Override default paste behavior
        this.listenTo(this.editor.editing.view.document, 'clipboardInput', ( evt, data ) => {
            const dataTransfer = data.dataTransfer;

            // All of our data is in HTML, as opposed to plain text
            const htmlData = dataTransfer.getData('text/html');
            if (!htmlData) {
                return;
            }

            // Convert the HTML to a view
            const content = this.editor.plugins.get('Clipboard')._htmlDataProcessor.toView(
                htmlData,
            );

            // Fire off an event that we'll intercept below
            this.fire( 'inputTransformation', { content, dataTransfer } );

            // You have to stop the event so other handlers don't run and overwrite content.
            evt.stop();
        });

        this.listenTo(this, 'inputTransformation', ( evt, data ) => {
            const modelFragment = this.editor.data.toModel(
                data.content,
                'section', // set this so the correct converters are called
            );

            if (modelFragment.childCount == 0) {
                return; // we couldn't create a model for this view
            }

            // Add the fragment into the model
            this.editor.model.insertContent(modelFragment);
        });
    }

    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.register( 'moduleBlock', {
            isObject: true,
            allowIn: 'section',
            allowAttributes: [
                // FIXME: Camelcase is broken with CKE built-in conversions, esp. on upcast
                'blockClasses',
                'data-icon',
                'data-radio-group',
            ],
        } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;
        const { editing, data, model } = editor;

        // <moduleBlock> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: ['module-block']
            },
            model: ( viewElement, modelWriter ) => {
                // Get existing classes on the element
                const srcClasses = viewElement.getAttribute('class') || 'module-block';

                // We need special handling for icon because it was originally set in 
                // <div class=...> and we're now keeping track of it in <div data-icon=...>
                const icon = (
                    // The data-icon attribute was already set on the element
                    viewElement.getAttribute('data-icon')
                    // The icon was in the element's class list
                    || srcClasses.split(" ").find( c => c.startsWith('module-block-') )
                    // Nothing was specified, use a default
                    || 'module-block-question'
                );

                // Remove icon from class
                const blockClasses = srcClasses.replace(icon, "").trim();

                let attributes = {
                    'blockClasses': blockClasses,
                    'data-icon': icon,
                }

                // Special radio-question support.
                // This attribute is set in insertradioquestioncommand.js.
                const radioGroup = viewElement.getAttribute( 'data-radio-group' );
                if ( radioGroup ) {
                    attributes['data-radio-group'] = radioGroup;
                }

                return modelWriter.createElement( 'moduleBlock', attributes );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'moduleBlock',
            view: ( modelElement, viewWriter ) => {
                let attributes = {
                    'class': modelElement.getAttribute('blockClasses') || 'module-block',
                    'data-icon': modelElement.getAttribute('data-icon') || 'module-block-question',
                }

                // Special radio-question support.
                // This attribute is set in insertradioquestioncommand.js.
                const radioGroup = modelElement.getAttribute( 'data-radio-group' );
                if ( radioGroup ) {
                    attributes['data-radio-group'] = radioGroup;
                }

                return viewWriter.createContainerElement( 'div', attributes );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'moduleBlock',
            view: ( modelElement, viewWriter ) => {
                let attributes = {
                    'class': modelElement.getAttribute('blockClasses') || 'module-block',
                    'data-icon': modelElement.getAttribute('data-icon') || 'module-block-question',
                }

                // Special radio-question support.
                // This attribute is set in insertradioquestioncommand.js.
                const radioGroup = modelElement.getAttribute( 'data-radio-group' );
                if ( radioGroup ) {
                    attributes['data-radio-group'] = radioGroup;
                }

                const moduleBlock = viewWriter.createContainerElement( 'div', attributes );

                return toWidget( moduleBlock, viewWriter, { label: 'module-block widget', hasSelectionHandle: true } );
            }
        } );

        conversion.attributeToAttribute( { model: 'data-icon', view: 'data-icon' } );
    }
}
