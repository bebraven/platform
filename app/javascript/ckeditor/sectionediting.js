import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { enablePlaceholder } from '@ckeditor/ckeditor5-engine/src/view/placeholder';
import { toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import InsertSectionCommand from './insertsectioncommand';

export default class SectionEditing extends Plugin {
    static get requires() {
        return [ Widget ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();

        this.editor.commands.add( 'insertSection', new InsertSectionCommand( this.editor ) );

        // Override the default keydown behavior to disallow adding anything but a single
        // moduleBlock inside a section.
        this.listenTo( this.editor.editing.view.document, 'keydown', ( evt, data ) => {
            const selection = this.editor.model.document.selection;
            const positionParent = selection.getLastPosition().parent;
            const selectedElement = selection.getSelectedElement();

            // Handle two cases: moduleBlock is selected, or cursor is in a paragraph inside the section.
            if ( ( selectedElement && selectedElement.name === 'moduleBlock' ) ||
                    ( positionParent.parent && positionParent.parent.name === 'section' ) ) {
                if ( data.domEvent.key === 'Enter' ) {
                    // On Enter, add a new section.
                    this.editor.execute( 'insertSection' )
                    data.preventDefault();
                    evt.stop();
                } else if ( !( data.domEvent.metaKey || data.domEvent.ctrlKey ) &&
                        ![ 'Backspace', 'Delete' ].includes( data.domEvent.key ) ) {
                    // Ignore most other keydowns, excluding control sequences and deletions.
                    // This sucks, but hopefully it's good enough until we drop sections.
                    data.preventDefault();
                    evt.stop();
                }
            }
        // Use 'highest' priority, because Widget._onKeydown listens at 'high'.
        // https://github.com/ckeditor/ckeditor5-widget/blob/bdeec63534d11a4fa682bb34990c698435bc13e3/src/widget.js#L92
        }, { priority: 'highest' } );
    }

    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.register( 'section', {
            allowIn: '$root',
            allowContentOf: '$root',
        } );

        schema.addChildCheck( ( context, childDefinition ) => {
            // Disallow sections within sections, at *any* level of nesting.
            if ( [...context.getNames()].includes( 'section' ) && childDefinition.name == 'section' ) {
                return false;
            }
        } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;
        const { editing, data, model } = editor;

        // <section> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'section',
                classes: ['content-section']
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'section' );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'section',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'section', {
                    'class': 'content-section',
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'section',
            view: ( modelElement, viewWriter ) => {
                const section = viewWriter.createContainerElement( 'section', {
                    'class': 'content-section',
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: section,
                    text: '[Empty section]',
                    isDirectHost: false
                } );

                return section;
            }
        } );
    }
}
