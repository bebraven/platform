import Command from '@ckeditor/ckeditor5-core/src/command';

export default class InsertVideoContentCommand extends Command {
    execute( url ) {
        this.editor.model.change( writer => {
            this.editor.model.insertContent( createVideoContent( writer, url ) );
        } );
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;
        const allowedIn = model.schema.findAllowedParent( selection.getFirstPosition(), 'moduleBlock' );

        this.isEnabled = allowedIn !== null;
    }
}

function createVideoContent( writer, url ) {
    const videoContent = writer.createElement(
        'moduleBlock',
        {
            'blockClasses': 'module-block',
            'data-icon': 'module-block-video',
        },
    );
    const content = writer.createElement( 'content' );
    const contentTitle = writer.createElement( 'contentTitle' );
    const contentBody = writer.createElement( 'contentBody' );
    const videoFigure = writer.createElement( 'videoFigure' );
    const videoIFrame = writer.createElement( 'videoIFrame', {src: url} );
    const videoFigCaption = writer.createElement( 'videoFigCaption' );
    const videoCaption = writer.createElement( 'videoCaption' );
    const videoDuration = writer.createElement( 'videoDuration' );
    const videoTranscript = writer.createElement( 'videoTranscript' );

    const contentParagraph = writer.createElement( 'paragraph' );
    const transcriptParagraph = writer.createElement( 'paragraph' );

    writer.append( content, videoContent );
    writer.append( contentTitle, content );
    writer.append( contentBody, content );
    writer.append( videoFigure, content );
    writer.append( videoIFrame, videoFigure );
    writer.append( videoFigCaption, videoFigure );
    writer.append( videoCaption, videoFigCaption );
    writer.append( videoDuration, videoFigCaption );
    writer.append( videoTranscript, videoFigCaption );

    // There must be at least one paragraph for the description to be editable.
    // See https://github.com/ckeditor/ckeditor5/issues/1464.
    writer.append( contentParagraph, contentBody );
    writer.append( transcriptParagraph, videoTranscript );

    return videoContent;
}
