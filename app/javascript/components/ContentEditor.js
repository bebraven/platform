import React, { Component } from 'react';
import ReactDOM from 'react-dom';
import { CKEditor } from '@ckeditor/ckeditor5-react';
import Rails from '@rails/ujs';

// Non-ckeditor React imports
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';
import 'react-tabs/style/react-tabs.css';

// The official CKEditor 5 instance inspector. It helps understand the editor view and model.
import CKEditorInspector from '@ckeditor/ckeditor5-inspector';

// NOTE: Use the editor from source (not a build)!
import BalloonEditor from '@ckeditor/ckeditor5-editor-balloon/src/ballooneditor';

import Essentials from '@ckeditor/ckeditor5-essentials/src/essentials';
import Autoformat from '@ckeditor/ckeditor5-autoformat/src/autoformat';
import BlockQuote from '@ckeditor/ckeditor5-block-quote/src/blockquote';
import BlockToolbar from '@ckeditor/ckeditor5-ui/src/toolbar/block/blocktoolbar';
import Bold from '@ckeditor/ckeditor5-basic-styles/src/bold';
import Heading from '@ckeditor/ckeditor5-heading/src/heading';
import Image from '@ckeditor/ckeditor5-image/src/image';
import ImageCaption from '@ckeditor/ckeditor5-image/src/imagecaption';
import ImageStyle from '@ckeditor/ckeditor5-image/src/imagestyle';
import ImageToolbar from '@ckeditor/ckeditor5-image/src/imagetoolbar';
import ImageUpload from '@ckeditor/ckeditor5-image/src/imageupload';
import ImageResize from '@ckeditor/ckeditor5-image/src/imageresize';
import Indent from '@ckeditor/ckeditor5-indent/src/indent';
import Italic from '@ckeditor/ckeditor5-basic-styles/src/italic';
import Link from '@ckeditor/ckeditor5-link/src/link';
import LinkImage from '@ckeditor/ckeditor5-link/src/linkimage';
import List from '@ckeditor/ckeditor5-list/src/list';
import MediaEmbed from '@ckeditor/ckeditor5-media-embed/src/mediaembed';
import Paragraph from '@ckeditor/ckeditor5-paragraph/src/paragraph';
import PasteFromOffice from '@ckeditor/ckeditor5-paste-from-office/src/pastefromoffice';
import Underline from '@ckeditor/ckeditor5-basic-styles/src/underline';
import Alignment from '@ckeditor/ckeditor5-alignment/src/alignment';
import Font from '@ckeditor/ckeditor5-font/src/font';
import SimpleUploadAdapter from '@ckeditor/ckeditor5-upload/src/adapters/simpleuploadadapter';
import HorizontalLine from '@ckeditor/ckeditor5-horizontal-line/src/horizontalline';

// CKEditor plugin implementing a content part widget to be used in the editor content.
import AttributeEditing from '../ckeditor/attributeediting';
import UniqueId from '../ckeditor/uniqueid';
import ElementIdEditing from '../ckeditor/elementidediting';
import InputUniqueAttributeEditing from '../ckeditor/inputuniqueattributeediting';
import ContentCommonEditing from '../ckeditor/contentcommonediting';
import LinkedInAuthorizationEditing from '../ckeditor/linkedinauthorizationediting';
import RadioQuestionEditing from '../ckeditor/radioquestionediting';
import PortalImageEditing from '../ckeditor/portalimageediting';
import WatchOutBoxEditing from '../ckeditor/watchoutboxediting';

// React components to render the list of content parts and the content part preview.
import CommandButton from './CommandButton';

// Other local imports.
import { getNamedAncestor, getNamedChildOrSibling } from '../ckeditor/utils';

// Tabs for different content views
const TABS = {
    DESIGN: 0,
    CODE: 1,
};

// Plugins to include in the build.
BalloonEditor.builtinPlugins = [
    // CKE plugins
    Essentials,
    Autoformat,
    BlockQuote,
    BlockToolbar,
    Bold,
    Heading,
    Image,
    ImageCaption,
    ImageStyle,
    ImageToolbar,
    ImageUpload,
    ImageResize,
    Indent,
    Italic,
    Link,
    LinkImage,
    List,
    MediaEmbed,
    Paragraph,
    PasteFromOffice,
    Alignment,
    Font,
    SimpleUploadAdapter,
    HorizontalLine,

    // Custom plugins
    AttributeEditing,
    UniqueId,
    ElementIdEditing,
    InputUniqueAttributeEditing,
    ContentCommonEditing,
    RadioQuestionEditing,
    PortalImageEditing,
    WatchOutBoxEditing,
    LinkedInAuthorizationEditing,
];

// Editor configuration.
BalloonEditor.defaultConfig = {
    blockToolbar: [
        'heading',
        '|',
        'bulletedList',
        'numberedList',
        '|',
        'indent',
        'outdent',
        '|',
        'alignment',
        '|',
        'imageUpload',
        'horizontalLine',
        '|',
        'undo',
        'redo'
    ],
    toolbar: {
        items: [
            'heading',
            '|',
            'bold',
            'italic',
            'link',
            'bulletedList',
            'numberedList',
            '|',
            'indent',
            'outdent',
            '|',
            'alignment',
            '|',
            'imageUpload',
            'undo',
            'redo'
        ]
    },
    image: {
        resizeUnit: 'px',
        toolbar: [
            'imageStyle:full',
            'imageStyle:side',
            '|',
            'imageTextAlternative',
            '|',
            'linkImage',
        ]
    },
    heading: {
        options: [
            { model: 'paragraph', title: 'Paragraph', class: 'ck-heading_paragraph' },
            { model: 'heading1', view: 'h2', title: 'Heading 1', class: 'ck-heading_h2' },
            { model: 'heading2', view: 'h3', title: 'Heading 2', class: 'ck-heading_h3' },
            { model: 'heading3', view: 'h4', title: 'Heading 3', class: 'ck-heading_h4' },
            { model: 'heading4', view: 'h5', title: 'Heading 4', class: 'ck-heading_h5' },
            { model: 'heading5', view: 'h6', title: 'Heading 5', class: 'ck-heading_h6' },
        ]
    },
    simpleUpload: {
        // The URL that the images are uploaded to.
        uploadUrl: '/file_upload.json',

        // Headers sent along with the XMLHttpRequest to the upload server.
        headers: {
            //Authorization: 'Bearer <JSON Web Token>'
            'X-CSRF-Token': Rails.csrfToken(),
        }
    },
    // This value must be kept in sync with the language defined in webpack.config.js.
    language: 'en'
};

class ContentEditor extends Component {
    constructor( props ) {
        super( props );

        // A place to store the reference to the editor instance created by the <CKEditor> component.
        // The editor instance is created asynchronously and is only available when the editor is ready.
        this.editor = null;

        this.state = {
            // The initial editor data. It is bound to the editor instance and will change as
            // the user types and modifies the content of the editor.
            editorData: props.custom_content['body'] || "",
            enabledCommands: [],
            modelPath: [],
            viewPath: [],
            selectedElement: undefined,
            tabIndex: window.location.search.includes('html=true') ? TABS.CODE : TABS.DESIGN,
        };

        // The configuration of the <CKEditor> instance.
        this.editorConfig = {};

        this.handleEditorFocusChange = this.handleEditorFocusChange.bind( this );
        this.handleEditorInit = this.handleEditorInit.bind( this );
        this.handleTabSelect = this.handleTabSelect.bind(this);
        this.handleSave = this.handleSave.bind(this);

        // Non-CKE UI functions.
        this.fileUpload = React.createRef();
        this.showFileUpload = this.showFileUpload.bind(this);
    }

    showFileUpload() {
        this.fileUpload.current.click();
    }

    // A handler executed when the current selection changes inside the CKEditor view.
    // It propogates state changes from CKEditor up to this React component, so we can
    // update the UI accordingly.
    handleEditorFocusChange() {
        // Get the model element names of the current element and all its ancestors.
        const modelSelection = this.editor.model.document.selection;
        // If the current selection is an element (as opposed to inside an editable),
        // use that as the last node in the path. Otherwise use the parent of the last
        // cursor position (generally, the editable element the cursor is inside).
        const selectedModelElement = modelSelection.getSelectedElement() || modelSelection.getLastPosition().parent;
        const modelAncestorNames = selectedModelElement.getAncestors().map( x => x.name );

        const commands = this.editor.commands;

        this.setState( {
            enabledCommands: [...commands.names()].filter( x => commands.get(x).isEnabled ),
            modelPath: modelAncestorNames.concat(selectedModelElement.name),
            selectedElement: selectedModelElement
        } );

        // The view selection works differently than the model selection, and we can't
        // always tie it to an element. Only update the view path if it's sane.
        const viewSelection = this.editor.editing.view.document.selection;
        let selectedViewElement;
        if ( viewSelection.getSelectedElement() ) {
            // If the current selection is an element (as opposed to inside an editable),
            // use that as the last node in the path.
            selectedViewElement = viewSelection.getSelectedElement();
        } else if ( viewSelection.focus ) {
            // If the current selection has a focus, use the focus's parent as the last
            // node in the path.
            selectedViewElement = viewSelection.focus.parent;
        }

        // If one of the above cases was true, we'll have a selectedViewElement, and we can
        // pull its ancestor chain.
        if ( selectedViewElement ) {
            const viewAncestorNames = selectedViewElement.getAncestors().map( x => x.name );

            this.setState( {
                viewPath: viewAncestorNames.concat(selectedViewElement.name)
            } );
        }
    }

    // A handler executed when the user types or modifies the raw html editor content.
    // It updates the state of the application.
    handleHTMLEditorDataChange( evt ) {
        this.setState( {
            editorData: evt.target.value,
        } );
    }

    // A handler executed when the editor has been initialized and is ready.
    // It synchronizes the initial data state and saves the reference to the editor instance.
    handleEditorInit( editor ) {
        this.editor = editor;

        // Store a reference to the editor in the window, just to make debugging easier.
        window.editor = editor;

        this.setState( {
            editorData: editor.getData()
        } );

        // Attach the focus handler, and call it once to set the initial state of the right sidebar buttons.
        editor.editing.view.document.selection.on('change', this.handleEditorFocusChange);
        this.handleEditorFocusChange();

        // CKEditor 5 inspector allows you to take a peek into the editor's model and view
        // data layers. Use it to debug the application and learn more about the editor.
        // Disable unless debug mode is enabled.
        if ( window.location.search === '?debug' ) {
            CKEditorInspector.attach( editor );
        }
    }

    handleSave(event) {
        if (this.state.tabIndex == TABS.DESIGN) { 
            // Update the raw HTML for "Code" tab
            this.setState({
                editorData: this.editor.getData(),
            });

            // Find the secret html field and overwrite it before we submit
            // because we won't re-render to update the value
            // before the form submission
            let element = document.getElementById("secret-html");
            element.value = this.editor.getData();
        }

        // Save
        document.forms[0].submit();
    }

    handleTabSelect(nextTab) {
        this.setState({
            tabIndex: nextTab,
        });
        if (nextTab == TABS.CODE) {
            // Update the raw HTML for "Code" tab display and editing
            this.setState({
                editorData: this.editor.getData(),
            });
        }
    }

    // Heading with "Save" button
    _renderHeader() {
        return (
            <header className="container-fluid">
                <div className="row align-items-center h-100">
                    <div className="col-sm-4 offset-sm-1">
                        <h1>Braven Content Editor</h1>
                    </div>
                    <div className="col-sm-6">
                        <span id="autosave-indicator" className="saved">Saved</span>
                        <span id="autosave-indicator" className="saving">Saving...</span>
                        <span onClick={(evt) => this.handleSave(evt)} className="btn-secondary">Save</span>
                    </div>
                </div>
            </header>
        );
    }

    // Custom content settings, like title, type
    _renderCustomContentSettings() {
    	const type = this.props.custom_content.type || '';

        return (
            <div id="toolbar-page-settings">
                <h4>Details</h4>
                <h2>
                    <input type="text"
                        name="custom_content[title]"
                        defaultValue={this.props.custom_content['title']}
                        placeholder="Title"
                    />
                </h2>
                <select name="custom_content[type]" defaultValue={type}>
            		<option disabled value=''>Select a Type</option>
            		<option>Project</option>
            		<option>Survey</option>
        		</select>
            </div>
        );
    }

    // Some elements have attributes that can be configured
    // The inputs to update those attributes are rendered above the CommandButtons
    // when the appropriate element is selected, for example:
    //   - Text areas and text inputs have a configurable placeholder
    //   - Headings have a configurable ID (for creating anchor links within a document)
    //   - Radio input values are configurable
    _renderContextualAttributes() {
        return (
            <div id="toolbar-contextual">
                {this.state.modelPath.map( modelElement => {
                    if ( ['textArea', 'textInput'].includes( modelElement ) ) {
                        return (
                            <>
                                <h4>Text Input</h4>
                                <div className="form-group">
                                    <label htmlFor='input-label'>Label (for screenreaders)</label>
                                    <input
                                        type='text'
                                        id='input-label'
                                        value={this.state['selectedElement'].getAttribute('aria-label')}
                                        onChange={( evt ) => {
                                            this.editor.execute( 'setAttributes', {
                                                'aria-label': evt.target.value,
                                            } );
                                        }}
                                        className='form-control'
                                        aria-describedby='label-help'
                                    />
                                    <small id='label-help' className='form-text'>
                                        <a href="https://www.aditus.io/aria/aria-label/#when-to-use" target="_blank">When to use (opens in new tab)</a>
                                    </small>
                                </div>
                                <div className="form-group">
                                    <label htmlFor='input-placeholder'>Placeholder</label>
                                    <input
                                        type='text'
                                        id='input-placeholder'
                                        value={this.state['selectedElement'].getAttribute('placeholder')}
                                        onChange={( evt ) => {
                                            this.editor.execute( 'setAttributes', {
                                                'placeholder': evt.target.value,
                                            } );
                                        }}
                                        className='form-control'
                                    />
                                </div>
                            </>
                        );
                    } else if ( modelElement.startsWith('heading') ) {
                        return (
                            <>
                                <h4>Heading</h4>
                                <div className="form-group">
                                    <label htmlFor='input-heading-id'>Heading Anchor</label>
                                    <input
                                        type='text'
                                        id='input-heading-id'
                                        value={'#' + this.state['selectedElement'].getAttribute('id')}
                                        disabled={ true }
                                        className='form-control'
                                        aria-describedby='heading-help'
                                    />
                                    <small id='heading-help' className='form-text'>Tip: Triple-click the heading anchor to select it all at once.</small>
                                </div>
                                <p>To link to this heading:</p>
                                <ol>
                                    <li>Add a new link (or edit an existing one),</li>
                                    <li>Copy the <strong>Heading Anchor</strong> above and use it as the link URL.</li>
                                </ol>
                            </>
                        );
                    } else if ( ['radioDiv' ].includes( modelElement ) ) {
                        const radioInput = getNamedChildOrSibling( 'radioInput', this.state['selectedElement']);
                        return (
                            <>
                                <h4>Input Value</h4>
                                <div className="form-group">
                                    <label htmlFor='input-value'>Value</label>
                                    <input
                                        id='input-value'
                                        value={radioInput.getAttribute('value')}
                                        onChange={( evt ) => {
                                            this.editor.execute( 'setAttributes', { 'value': evt.target.value }, radioInput );
                                        }}
                                        className='form-control'
                                    />
                                </div>
                            </>
                        );
                    }
                } )
            }
            </div>
        );
    }

    // List of CommandButtons for inserting content in editor tabs
    _renderEditorCommands() {
        const elementComponents = Object.entries({
            'insertTextArea': 'Text Area',
            'insertTextInput': 'Text Input',
            'insertWatchOutBox': '"Watch Out" Box',
            'insertRadioQuestion': 'Radio List',
            'insertNumericalSelector': '1 - 10 Dropdown',
            'insertIndustrySelector': 'Industry Selector',

        }).map( ([key, name]) => this._renderCommandButton(key, name) );
        return (
            <div id="toolbar-components">
                <h4>Insert Component</h4>
                <ul key="content-part-list-elements" className="widget-list">
                	{elementComponents}
                    <input
                        type="file"
                        style={{ display: "none" }}
                        ref={this.fileUpload}
                        onChange={e => {
                            this.editor.execute( 'imageUpload', {file: e.target.files[0]} );
                            this.editor.editing.view.focus();
                        }}
                    />
                    <CommandButton
                        key="imageUpload"
                        enabled={this.state.enabledCommands.includes('imageUpload')}
                        onClick={this.showFileUpload}
                        onClickDisabled={() => this.editor.editing.view.focus()}
                        name='Image (Upload)'
                    />
                    <CommandButton
                        key="imageInsert"
                        enabled={this.state.enabledCommands.includes('imageInsert')}
                        onClick={( id ) => {
                            const url = window.prompt('URL', 'http://placekitten.com/200/300');
                            this.editor.execute( 'imageInsert', {source: url} );
                            this.editor.editing.view.focus();
                        }}
                        onClickDisabled={() => this.editor.editing.view.focus()}
                        name='Image (URL)'
                    />
                    <CommandButton
                        key="linkedInInsert"
                        enabled={this.state.enabledCommands.includes('insertLinkedInAuthorization')}
                        onClick={() => {
                            this.editor.execute( 'insertLinkedInAuthorization', window.location.hostname);
                            this.editor.editing.view.focus();
                        }}
                        onClickDisabled={() => this.editor.editing.view.focus()}
                        name='LinkedIn Authorization'
                    />
                </ul>
            </div>
        );
    }

    _renderCommandButton(key, name) {
        return (
            <CommandButton
                key={key}
                enabled={this.state.enabledCommands.includes(key)}
                onClick={( id ) => {
                    this.editor.execute( key );
                    this.editor.editing.view.focus();
                }}
                onClickDisabled={() => this.editor.editing.view.focus()}
                name={name}
            />
        );
    }

    // The Design (CKE) and Code (HTML) content editor tabs
    _renderEditorTabs() {
        return (
            <Tabs className="container-fluid"
                defaultIndex={this.state.tabIndex}
                onSelect={(evt) => this.handleTabSelect(evt)}>
                <div id="workspace">
                    <TabList id="view-mode" className="row justify-content-center">
                        <div className="col-sm-6">
                            <Tab>Design</Tab>
                            <Tab>Code</Tab>
                        </div>
                    </TabList>
                    <TabPanel className="row justify-content-center">
                        <div id="wysiwyg-container" className="bz-assignment col-sm-6">
                            <CKEditor
                                editor={BalloonEditor}
                                data={this.state.editorData}
                                config={this.editorConfig}
                                onReady={this.handleEditorInit}
                            />
                            <textarea
                                id="secret-html"
                                value={this.state.editorData}
                                className="secret-html"
                                readOnly={true}
                                name="custom_content[body]"
                            />
                        </div>
                    </TabPanel>
                    <TabPanel className="row justify-content-center">
                        <div id="raw-html-container" className="col-sm-12">
                            <textarea
                                value={this.state.editorData}
                                onChange={(evt) => this.handleHTMLEditorDataChange(evt)}
                                name="custom_content[body]"
                            />
                        </div>
                    </TabPanel>
                </div>
            </Tabs>
        );
    }

    render() {
        // The application renders two columns:
        // * in the left one, the <CKEditor> and the textarea displaying live
        //   editor data are rendered.
        // * in the right column, available <CommandButtons> to choose from.
        return (
            <div key="content-editor">
                {this._renderHeader()}
                <main>
                    <div id="vertical-toolbar">
                        {this._renderCustomContentSettings()}
                        {this._renderContextualAttributes()}
                        {this._renderEditorCommands()}
                    </div>
                    {this._renderEditorTabs()}
                </main>
            </div>
        );
    }
}

export default ContentEditor;
