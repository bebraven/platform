import Command from '@ckeditor/ckeditor5-core/src/command';
import { getNamedAncestor } from './utils';

export default class InsertSectionCommand extends Command {
    execute() {
        this.editor.model.change( writer => {
            const selection = this.editor.model.document.selection;
            const position = selection.getFirstPosition();

            const section = getNamedAncestor( 'section', position );
            if ( section ) {
                // IFF we're not in the root, before inserting, modify the current
                // selection to after the section.
                writer.setSelection( section, 'after' );
            }

            const newSection = createSection( writer );
            this.editor.model.insertContent( newSection );

            // HACK: If there's nothing after this section, append a paragraph, to
            // allow typing outside of the section. If we don't do this check first,
            // we might end up with a bunch of paragraphs instead of just one.
            if ( !newSection.nextSibling ) {
                writer.insertElement( 'paragraph', newSection, 'after' );
            }

            writer.setSelection( newSection, 'in' );
        } );
    }

    refresh() {
        const model = this.editor.model;
        const selection = model.document.selection;
        const allowedIn = model.schema.findAllowedParent( selection.getFirstPosition(), 'section' );

        this.isEnabled = allowedIn !== null;
    }
}

function createSection( writer ) {
    const section = writer.createElement( 'section' );

    // There must be at least one paragraph for the section to be editable.
    // See https://github.com/ckeditor/ckeditor5/issues/1464.
    writer.appendElement( 'paragraph', section );

    return section;
}
