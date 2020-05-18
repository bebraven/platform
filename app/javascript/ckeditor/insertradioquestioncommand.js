import Command from '@ckeditor/ckeditor5-core/src/command';
import uid from '@ckeditor/ckeditor5-utils/src/uid';

export default class InsertRadioQuestionCommand extends Command {
    execute() {
        this.editor.model.change( writer => {
            this.editor.model.insertContent( createRadioQuestion( writer ) );
        } );
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;
        const allowedIn = model.schema.findAllowedParent( selection.getFirstPosition(), 'moduleBlock' );

        this.isEnabled = allowedIn !== null;
    }
}

function createRadioQuestion( writer ) {
    const radioGroup = uid();
    // Value must be unique within each group, but otherwise doesn't matter.
    // No reason to tie in retained data or anything, we can just use "1".
    const radioFirstValue = '1';
    const radioFirstID = [radioGroup, radioFirstValue].join('_');

    const radioQuestion = writer.createElement( 'moduleBlock', {'data-radio-group': radioGroup} );
    const question = writer.createElement( 'question', { 'data-grade-as': 'radio' } );
    const questionTitle = writer.createElement( 'questionTitle' );
    const questionBody = writer.createElement( 'questionBody' );
    const questionForm = writer.createElement( 'questionForm' );
    const questionFieldset = writer.createElement( 'questionFieldset' );
    const doneButton = writer.createElement( 'doneButton' );
    const radioDiv = writer.createElement( 'radioDiv' );
    const radioInput = writer.createElement( 'radioInput', {
        name: radioGroup,
        id: radioFirstID,
        value: radioFirstValue,
    } );
    const radioLabel = writer.createElement( 'radioLabel', { 'for': radioFirstID } );
    const radioInlineFeedback = writer.createElement( 'radioInlineFeedback' );
    const answer = writer.createElement( 'answer' );
    const answerTitle = writer.createElement( 'answerTitle' );
    const answerText = writer.createElement( 'answerText' );

    const questionParagraph = writer.createElement( 'paragraph' );
    const answerParagraph = writer.createElement( 'paragraph' );

    writer.append( question, radioQuestion );
    writer.append( questionTitle, question );
    writer.append( questionBody, question );
    writer.append( questionForm, question );
    writer.append( questionFieldset, questionForm );
    writer.append( doneButton, questionForm );
    writer.append( radioDiv, questionFieldset );
    writer.append( radioInput, radioDiv );
    writer.append( radioLabel, radioDiv );
    writer.append( radioInlineFeedback, radioDiv );
    writer.append( answer, radioQuestion );
    writer.append( answerTitle, answer );
    writer.append( answerText, answer );
    // There must be at least one paragraph for the description to be editable.
    // See https://github.com/ckeditor/ckeditor5/issues/1464.
    writer.append( questionParagraph, questionBody );
    writer.append( answerParagraph, answerText );

    // Add text to empty editables where placeholders don't work.
    writer.insertText( 'Radio label', radioLabel );

    return radioQuestion;
}
