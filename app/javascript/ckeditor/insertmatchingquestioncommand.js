import Command from '@ckeditor/ckeditor5-core/src/command';
import { findOptimalInsertionPosition } from '@ckeditor/ckeditor5-widget/src/utils';

export default class InsertMatchingQuestionCommand extends Command {
    execute() {
        const model = this.editor.model;
        const selection = model.document.selection;
        const tableUtils = this.editor.plugins.get( 'TableUtils' );

        const rows = 2;
        const columns = 2;

        //const insertPosition = findOptimalInsertionPosition( selection, model );

        this.editor.model.change( writer => {
            const matchingQuestion = writer.createElement( 'moduleBlock' );
            const question = writer.createElement( 'question', {'data-grade-as': 'matching'} );
            const questionTitle = writer.createElement( 'questionTitle' );
            const questionBody = writer.createElement( 'questionBody' );
            const matchingTable = writer.createElement( 'matchingTable' );
            const doneButton = writer.createElement( 'doneButton' );
            const matchingTableBody = writer.createElement( 'matchingTableBody' );
            const matchingTableRow1 = writer.createElement( 'matchingTableRow' );
            const matchingTableRow2 = writer.createElement( 'matchingTableRow' );
            const matchingTableCell11 = writer.createElement( 'matchingTableCell' );
            const matchingTableCell12 = writer.createElement( 'matchingTableCell' );
            const matchingTableCell13 = writer.createElement( 'matchingTableCell' );
            const matchingTableCell21 = writer.createElement( 'matchingTableCell' );
            const matchingTableCell22 = writer.createElement( 'matchingTableCell' );
            const matchingTableCell23 = writer.createElement( 'matchingTableCell' );

            const questionParagraph = writer.createElement( 'paragraph' );
            
            writer.append( question, matchingQuestion );
            writer.append( questionTitle, question );
            writer.append( questionBody, question );
            writer.append( questionBody, question );
            writer.append( matchingTable, question );
            writer.append( doneButton, question );
            writer.append( matchingTableBody, matchingTable );
            writer.append( matchingTableRow1, matchingTableBody );
            writer.append( matchingTableRow2, matchingTableBody );
            writer.append( matchingTableCell11, matchingTableRow1 );
            writer.append( matchingTableCell12, matchingTableRow1 );
            writer.append( matchingTableCell13, matchingTableRow1 );
            writer.append( matchingTableCell21, matchingTableRow2 );
            writer.append( matchingTableCell22, matchingTableRow2 );
            writer.append( matchingTableCell23, matchingTableRow2 );

            // There must be at least one paragraph for the description to be editable.
            // See https://github.com/ckeditor/ckeditor5/issues/1464.
            writer.append( questionParagraph, questionBody );
            
            // Add text to empty editables, to get around the lack of placeholder support.
            writer.insertText( 'Title', matchingTableCell11 );
            writer.insertText( 'Text', matchingTableCell12 );
            writer.insertText( 'Text', matchingTableCell13 );
            writer.insertText( 'Title', matchingTableCell21 );
            writer.insertText( 'Text', matchingTableCell22 );
            writer.insertText( 'Text', matchingTableCell23 );

            model.insertContent( matchingQuestion );
            //writer.setSelection( writer.createPositionAt( table.getNodeByPath( [ 0, 0, 0 ] ), 0 ) );
        } );
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;
        const allowedIn = model.schema.findAllowedParent( selection.getFirstPosition(), 'moduleBlock' );

        this.isEnabled = allowedIn !== null;
    }
}
