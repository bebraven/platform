import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import Table from '@ckeditor/ckeditor5-table/src/table';
import InsertMatrixQuestionCommand from './insertmatrixquestioncommand';

export default class MatrixQuestionEditing extends Plugin {
    static get requires() {
        return [ Widget, Table ];
    }

    init() {
        this._defineSchema();

        this.editor.commands.add( 'insertMatrixQuestion', new InsertMatrixQuestionCommand( this.editor ) );
    }

    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.extend( 'table', {
            allowIn: 'questionFieldset',
        } );
    }
}
