import Command from '@ckeditor/ckeditor5-core/src/command';

export default class InsertMatrixQuestionCommand extends Command {
    execute( options ) {
        this.editor.model.change( writer => {
            const { matrixQuestion, selection } = createMatrixQuestion( writer, options );
            this.editor.model.insertContent( matrixQuestion );
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

function createMatrixQuestion( writer, options ) {
    const matrixQuestion = writer.createElement( 'moduleBlock' );
    const question = writer.createElement( 'question', {'data-grade-as': 'matrix'} );
    const questionTitle = writer.createElement( 'questionTitle' );
    const questionBody = writer.createElement( 'questionBody' );
    const questionForm = writer.createElement( 'questionForm' );
    const questionFieldset = writer.createElement( 'questionFieldset' );
    const table = writer.createElement( 'table' );
    const doneButton = writer.createElement( 'doneButton' );
    const answer = writer.createElement( 'answer' );
    const answerTitle = writer.createElement( 'answerTitle' );
    const answerText = writer.createElement( 'answerText' );

    const questionParagraph = writer.createElement( 'paragraph' );
    const answerParagraph = writer.createElement( 'paragraph' );

    writer.append( question, matrixQuestion );
    writer.append( questionTitle, question );
    writer.append( questionBody, question );
    writer.append( questionForm, question );
    writer.append( questionFieldset, questionForm );
    writer.append( table, questionFieldset );
    writer.append( doneButton, questionForm );
    writer.append( answer, matrixQuestion );
    writer.append( answerTitle, answer );
    writer.append( answerText, answer );
    // There must be at least one paragraph for the description to be editable.
    // See https://github.com/ckeditor/ckeditor5/issues/1464.
    writer.append( questionParagraph, questionBody );
    writer.append( answerParagraph, answerText );

    // Create options['rows'] rows and options['columns'] columns inside the table
    for ( let i = 0; i < options['rows']; i++ ) {
        const row = writer.createElement( 'tableRow' );
        writer.append( row, table );

        for ( let j = 0; j < options['columns']; j++ ) {
            writer.append( writer.createElement( 'tableCell' ), row );
        }
    }

    // Return the created element and desired selection position.
    const selection = writer.createPositionAt( questionTitle, 0 );

    return { matrixQuestion, selection };
}
