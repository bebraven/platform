import Command from '@ckeditor/ckeditor5-core/src/command';

export default class InsertBlockquoteContentCommand extends Command {
    execute() {
        this.editor.model.change( writer => {
            const { blockquoteContent, selection } = createBlockquoteContent( writer );
            this.editor.model.insertContent( blockquoteContent );
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

function createBlockquoteContent( writer ) {
    const blockquoteContent = writer.createElement(
        'moduleBlock',
        { 'blockClasses': 'module-block block-quote-bg' },
    );
    const content = writer.createElement( 'content' );
    const quote = writer.createElement( 'blockquoteQuote' );
    const paragraph = writer.createElement( 'paragraph' );
    const citation = writer.createElement( 'blockquoteCitation' );

    writer.append( content, blockquoteContent );
    writer.append( quote, content );
    writer.append( paragraph, quote );
    writer.append( citation, quote );

    // Add text to empty editables, to get around the lack of placeholder support.
    // There must be at least one paragraph for the description to be editable.
    // See https://github.com/ckeditor/ckeditor5/issues/1464.
    writer.insertText( 'Quote', paragraph );

    // Return the created element and desired selection position.
    const selection = writer.createPositionAt( paragraph, 0 );

    return { blockquoteContent, selection };
}
