import Command from '@ckeditor/ckeditor5-core/src/command';
import { findAllowedParentIgnoreLimit, getNamedAncestor } from './utils';
import uid from '@ckeditor/ckeditor5-utils/src/uid';

export default class InsertChecklistOtherCommand extends Command {
    execute( placeholder ) {
        this.editor.model.change( writer => {
            // Before inserting, modify the current selection to after the checkboxDiv.
            const selection = this.editor.model.document.selection;
            const selectedElement = selection.getSelectedElement();
            const position = selection.getFirstPosition();

            // Find the checkboxDiv.
            let checkboxDiv;
            if ( selectedElement && selectedElement.name === 'checkboxDiv' ) {
                // The current selection is a checkboxDiv.
                checkboxDiv = selectedElement;
            } else if ( [ 'checkboxLabel', 'checkboxInlineFeedback' ].includes(position.parent.name) ) {
                // The cursor is inside one of the elements in the checkboxDiv, so find its ancestor checkboxDiv.
                checkboxDiv = getNamedAncestor( 'checkboxDiv', position );
            } else {
                // In any other case, just return without doing anything.
                // This makes us a bit more robust, in case we modify checkboxDiv later on.
                return;
            }
            writer.setSelection( checkboxDiv, 'after' );
            this.editor.model.insertContent( createChecklistOther( writer, placeholder ) );

            // Checklists with "other" options always need the "dont-mix" class on the fieldset, so
            // add that now.
            const fieldset = getNamedAncestor( 'questionFieldset', position );
            writer.setAttributes( {'class': 'dont-mix'}, fieldset );
        } );
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;

        // Explicitly ignore Limit behavior, because checkboxLabel is a limit.
        // This feels hacky, but should be safe here.
        const allowedIn = findAllowedParentIgnoreLimit( model.schema, selection.getFirstPosition(), 'checkboxDiv' );

        this.isEnabled = allowedIn !== null;
    }
}

function createChecklistOther( writer, placeholder ) {
    const checkboxDiv = writer.createElement( 'checkboxDiv' );
    const checkboxInput = writer.createElement( 'checkboxInput', {
        'data-bz-optional-magic-field': true,
        'data-correctness': 'maybe',
    } );
    const checkboxLabel = writer.createElement( 'checkboxLabel' );
    const textareaId = uid()
    const textareaLabel = writer.createElement( 'textareaLabel', {
        id: textareaId
    } );
    const textArea = writer.createElement( 'textArea', {
        placeholder,
        'data-bz-optional-magic-field': true,
        'aria-labelledby': textareaId
    } );

    writer.append( checkboxInput, checkboxDiv );
    writer.append( checkboxLabel, checkboxDiv );
    writer.append( textArea, checkboxDiv );
    writer.append( textareaLabel, checkboxDiv );

    // Add text to empty editables where placeholders don't work.
    writer.insertText( 'Other:', checkboxLabel );
    writer.insertText( 'Enter your answer:', textareaLabel );

    return checkboxDiv;
}
