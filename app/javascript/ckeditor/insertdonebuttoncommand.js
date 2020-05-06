import Command from '@ckeditor/ckeditor5-core/src/command';
import { getNamedChildOrSibling, getNamedAncestor } from './utils';

export default class InsertDoneButtonCommand extends Command {
    execute() {
        this.editor.model.change( writer => {
            // Note: This command only works in content blocks, not question or answer blocks.
            // The selection is expected to be somewhere in or on the module-block.
            // Before inserting, we must modify the current selection to the end of the content block.
            const selection = this.editor.model.document.selection;
            const selectedElement = selection.getSelectedElement();
            const position = selection.getFirstPosition();

            const contentBlock = findContentBlock( selectedElement, position );
            if ( !contentBlock ) {
                return;
            }

            writer.setSelection( contentBlock, 'end' );
            this.editor.model.insertContent( createDoneButton( writer ) );

            // ♪ Put that thing back where it came from, or so help meeee ♫
            if ( selectedElement ) {
                writer.setSelection( selectedElement, 'on' );
            } else {
                writer.setSelection( position );
            }
        } );
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;
        const selectedElement = selection.getSelectedElement();
        const position = selection.getFirstPosition();
        const allowedIn = findContentBlock( selectedElement, position );

        this.isEnabled = allowedIn !== undefined;
    }
}

function createDoneButton( writer ) {
    const doneButton = writer.createElement( 'doneButton' );
    return doneButton;
}

function findContentBlock( selectedElement, position ) {
    // Find the content block.
    let contentBlock;
    if ( selectedElement && 'moduleBlock' === selectedElement.name ) {
        // The current selection is a moduleBlock; check for a content block inside it.
        contentBlock = getNamedChildOrSibling( 'content', selectedElement );

    } else if ( contentBlock = getNamedAncestor( 'content', position ) ) {
        // The cursor is inside the content block; we've already found it.
    }

    return contentBlock;
}
