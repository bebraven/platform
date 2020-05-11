import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import InsertTableContentCommand from './inserttablecontentcommand';

export default class TableContentEditing extends Plugin {
    static get requires() {
        return [ Widget ];
    }

    init() {
        this._defineSchema();

        this.editor.commands.add( 'insertTableContent', new InsertTableContentCommand( this.editor ) );
    }

    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.extend( 'slider', {
            allowIn: 'tableCell'
        } );
    }
}
