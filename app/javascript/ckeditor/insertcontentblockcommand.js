import Command from '@ckeditor/ckeditor5-core/src/command';

export default class InsertContentBlockCommand extends Command {
    execute( classes='module-block' ) {
        this.editor.model.change( writer => {
            const { contentBlock, selection } = createContentBlock( writer, classes );
            this.editor.model.insertContent( contentBlock );
            writer.setSelection( selection );
        } );
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;
        const allowedIn = model.schema.findAllowedParent( selection.getFirstPosition(), 'moduleBlock' );

        this.isEnabled = allowedIn !== null;
    }
}

function createContentBlock( writer, classes ) {
    const contentBlock = writer.createElement(
        'moduleBlock',
        {
            'class': classes,
            'data-icon':'module-block-reflection',
        },
    );
    const content = writer.createElement( 'content' );
    const contentTitle = writer.createElement( 'contentTitle' );
    const contentBody = writer.createElement( 'contentBody' );

    const contentParagraph = writer.createElement( 'paragraph' );

    writer.append( content, contentBlock );
    writer.append( contentTitle, content );
    writer.append( contentBody, content );
    // There must be at least one paragraph for the description to be editable.
    // See https://github.com/ckeditor/ckeditor5/issues/1464.
    writer.append( contentParagraph, contentBody );

    // Return the created element and desired selection position.
    const selection = writer.createPositionAt( contentTitle, 0 );

    return { contentBlock, selection };
}
