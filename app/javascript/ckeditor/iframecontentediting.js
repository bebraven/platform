import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { toWidget } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import InsertIFrameContentCommand from './insertiframecontentcommand';

export default class IFrameContentEditing extends Plugin {
    static get requires() {
        return [ Widget ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();

        this.editor.commands.add( 'insertIFrameContent', new InsertIFrameContentCommand( this.editor ) );
    }


    /**
     * Example valid structure:
     *
     * <$root>
     *   <iframe/>
     * </$root>
     */
    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.register( 'iframe', {
            isObject: true,
            allowIn: [ 'content', 'contentBody', '$root' ],
            allowAttributes: [ 'src', 'width' ]
        } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;
        const { editing, data, model } = editor;

        // <iframe> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'iframe',
                classes: ['iframe-content']
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'iframe', {
                    'src': viewElement.getAttribute( 'src' ),
                    'width': viewElement.getAttribute( 'width' ),
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'iframe',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEmptyElement( 'iframe', {
                    'src': modelElement.getAttribute( 'src' ),
                    'width': modelElement.getAttribute( 'width' ),
                    'class': 'iframe-content'
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'iframe',
            view: ( modelElement, viewWriter ) => {
                const iframe = viewWriter.createEmptyElement( 'iframe', {
                    'src': modelElement.getAttribute( 'src' ),
                    'width': modelElement.getAttribute( 'width' ),
                    'class': 'iframe-content'
                } );

                return toWidget( iframe, viewWriter, { label: 'iframe widget' } )
            }
        } );
    }
}
