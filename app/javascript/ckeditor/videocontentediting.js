import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { enablePlaceholder } from '@ckeditor/ckeditor5-engine/src/view/placeholder';
import { toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import InsertVideoContentCommand from './insertvideocontentcommand';

export default class VideoContentEditing extends Plugin {
    static get requires() {
        return [ Widget ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();

        this.editor.commands.add( 'insertVideoContent', new InsertVideoContentCommand( this.editor ) );
    }

    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.register( 'videoFigure', {
            isObject: true,
            allowIn: [ 'content', 'question', '$root' ],
        } );

        schema.register( 'videoIFrame', {
            isObject: true,
            allowIn: 'videoFigure',
            allowAttributes: [ 'src', 'allow', 'allowfullscreen', 'frameborder', 'height', 'width' ]
        } );

        schema.register( 'videoFigCaption', {
            isLimit: true,
            allowIn: [ 'videoFigure' ],
        } );

        schema.register( 'videoCaption', {
            allowIn: 'videoFigCaption',
            isLimit: true,
            allowContentOf: [ '$block' ],
        } );

        schema.register( 'videoDuration', {
            allowIn: 'videoFigCaption',
            isLimit: true,
            allowContentOf: [ '$block' ],
        } );

        schema.register( 'videoTranscript', {
            allowIn: 'videoFigCaption',
            isLimit: true,
            allowContentOf: [ '$root' ],
        } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;
        const { editing, data, model } = editor;

        // <videoContent> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: ['module-block', 'module-block-video']
            },
            model: 'videoContent'
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'videoContent',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'div', {
                    'class': 'module-block module-block-video'
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'videoContent',
            view: ( modelElement, viewWriter ) => {
                const videoContent = viewWriter.createContainerElement( 'div', {
                    'class': 'module-block module-block-video',
                } );

                return toWidget( videoContent, viewWriter, { label: 'video widget' } );
            }
        } );

        // <videoFigure> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'figure',
                classes: ['video']
            },
            model: 'videoFigure'
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'videoFigure',
            view: {
                name: 'figure',
                classes: ['video']
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'videoFigure',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createContainerElement( 'figure', {
                    'class': 'video',
                } );
            }
        } );

        // <videoIFrame> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'iframe',
                attributes: {
                    allow: 'encrypted-media',
                    allowfullscreen: 'allowfullscreen',
                    frameborder: '0',
                    height: '315',
                    width: '560'
                }
            },
            model: ( viewElement, modelWriter ) => {
                return modelWriter.createElement( 'videoIFrame', {
                    'src': viewElement.getAttribute( 'src' )
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'videoIFrame',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEmptyElement( 'iframe', {
                    'src': modelElement.getAttribute( 'src' ),
                    'allow': 'encrypted-media',
                    'allowfullscreen': 'allowfullscreen',
                    'frameborder': '0',
                    'height': '315',
                    'width': '560'
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'videoIFrame',
            view: ( modelElement, viewWriter ) => {
                const iframe = viewWriter.createEmptyElement( 'iframe', {
                    'src': modelElement.getAttribute( 'src' ),
                    'allow': 'encrypted-media',
                    'allowfullscreen': 'allowfullscreen',
                    'frameborder': '0',
                    'height': '315',
                    'width': '560'
                } );

                return toWidget( iframe, viewWriter, { label: 'video iframe widget' } )
            }
        } );

        // <videoFigCaption> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'figcaption',
                classes: ['video-caption-container']
            },
            model: 'videoFigCaption'
        } );
        conversion.for( 'downcast' ).elementToElement( {
            model: 'videoFigCaption',
            view: {
                name: 'figcaption',
                classes: ['video-caption-container']
            },
        } );

        // The next 3 upcast converters must be high priority because of the
        // ambiguously-defined 'question' upcast. :/
        // <videoCaption> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: ['video-caption']
            },
            model: 'videoCaption',
            converterPriority: 'high',
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'videoCaption',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'div', {
                    'class': 'video-caption'
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'videoCaption',
            view: ( modelElement, viewWriter ) => {
                const videoCaption = viewWriter.createEditableElement( 'div', {
                    'class': 'video-caption',
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: videoCaption,
                    text: 'Video caption',
                } );

                return toWidgetEditable( videoCaption, viewWriter );
            }
        } );

        // <videoDuration> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: ['media-duration']
            },
            model: 'videoDuration',
            converterPriority: 'high',
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'videoDuration',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'div', {
                    'class': 'media-duration'
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'videoDuration',
            view: ( modelElement, viewWriter ) => {
                const videoDuration = viewWriter.createEditableElement( 'div', {
                    'class': 'media-duration',
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: videoDuration,
                    text: 'Video duration',
                } );

                return toWidgetEditable( videoDuration, viewWriter );
            }
        } );

        // <videoTranscript> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'div',
                classes: ['transcript']
            },
            model: 'videoTranscript',
            converterPriority: 'high',
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'videoTranscript',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'div', {
                    'class': 'transcript'
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'videoTranscript',
            view: ( modelElement, viewWriter ) => {
                const videoTranscript = viewWriter.createEditableElement( 'div', {
                    'class': 'transcript',
                } );

                enablePlaceholder( {
                    view: editing.view,
                    element: videoTranscript,
                    text: 'Video transcript',
                    isDirectHost: false
                } );

                return toWidgetEditable( videoTranscript, viewWriter );
            }
        } );
    }
}
