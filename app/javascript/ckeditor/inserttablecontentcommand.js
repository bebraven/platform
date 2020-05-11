import Command from '@ckeditor/ckeditor5-core/src/command';

export default class InsertTableCommand extends Command {
    execute( options = {} ) {
        const model = this.editor.model;
        const selection = model.document.selection;
        const tableUtils = this.editor.plugins.get( 'TableUtils' );

        const rows = parseInt( options.rows ) || 2;
        const columns = parseInt( options.columns ) || 2;

        this.editor.model.change( writer => {
            const tableContent = writer.createElement( 'moduleBlock' );
            const content = writer.createElement( 'content' );
            const contentTitle = writer.createElement( 'contentTitle' );
            const contentBody = writer.createElement( 'contentBody' );

            writer.append( content, tableContent );
            writer.append( contentTitle, content );
            writer.append( contentBody, content );

            // Insert table after the title and body.
            model.insertContent( tableContent );
            writer.setSelection( writer.createPositionAt( content, 2 ) );
            this.editor.execute( 'insertTable', { rows: rows, columns: columns } );
        } );
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;
        const allowedIn = model.schema.findAllowedParent( selection.getFirstPosition(), 'moduleBlock' );

        this.isEnabled = allowedIn !== null;
    }
}
