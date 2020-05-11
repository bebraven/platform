import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { toWidget } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import InsertTextAreaQuestionCommand from './inserttextareaquestioncommand';
import InsertTextAreaCommand from './inserttextareacommand';

export default class TextAreaQuestionEditing extends Plugin {
    static get requires() {
        return [ Widget ];
    }

    init() {
        this.editor.commands.add( 'insertTextAreaQuestion', new InsertTextAreaQuestionCommand( this.editor ) );
        this.editor.commands.add( 'insertTextArea', new InsertTextAreaCommand( this.editor ) );
    }
}
