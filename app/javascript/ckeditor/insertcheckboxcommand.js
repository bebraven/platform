import Command from '@ckeditor/ckeditor5-core/src/command';
import { findAllowedParentIgnoreLimit, getNamedAncestor } from './utils';

export default class InsertCheckboxCommand extends Command {
    execute() {
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

            const { checkbox, checkboxPosition } = createCheckbox( writer );
            this.editor.model.insertContent( checkbox );
            writer.setSelection( checkboxPosition );

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

function createCheckbox( writer ) {
    const checkboxDiv = writer.createElement( 'checkboxDiv' );
    const checkboxInput = writer.createElement( 'checkboxInput' );
    const checkboxLabel = writer.createElement( 'checkboxLabel' );
    const checkboxInlineFeedback = writer.createElement( 'checkboxInlineFeedback' );

    writer.append( checkboxInput, checkboxDiv );
    writer.append( checkboxLabel, checkboxDiv );
    writer.append( checkboxInlineFeedback, checkboxDiv );

    // Add text to empty editables where placeholders don't work.
    writer.insertText( 'Checkbox label', checkboxLabel );
    const position = writer.createPositionAt( checkboxLabel, 0 );

    return {
        checkbox: checkboxDiv,
        checkboxPosition: position,
    };
}
