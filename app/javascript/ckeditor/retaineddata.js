import Plugin from '@ckeditor/ckeditor5-core/src/plugin';

const RETAINED_DATA_ATTRIBUTE = 'data-bz-retained';

/**
 * The retained data plugin. It is used by all plugins that must create new
 * retained data fields, e.g. ChecklistQuestionEditing.
 *
 * The basic concept is:
 *
 * - The plugin is initialized when the CKEditor component is loaded.
 * - It reads a `pageId` set in the global plugin config, and uses this to form a page-specific
 *   prefix for retained data ids. Any IDs not matching that prefix will be ignored.
 * - It listens to the view document for `change:attributes` events to look for new or changed
 *   retained data IDs. At initial page load, that means *all* IDs will be processed.
 * - It maintains an internal ID counter, which at page load is set to the highest previously used
 *   ID in the document, and is incremented every time `getNextId()` or `getNextCount()` is called.
 *
 * Points to note:
 *
 * - Consecutively generated IDs are *NOT* guaranteed to use consecutive integers (and usually won't).
 * - Only the *FIRST* root in multi-root editors is supported. (This could be changed if we ever need
 *   to use a multi-root editor.)
 */
export default class RetainedData extends Plugin {
    static get pluginName() {
        return 'RetainedData';
    }

    init() {
        const editor = this.editor;
        const editingDoc = editor.editing.view.document;

        const pageId = editor.config.get( 'retainedData.pageId' );

        this._idCounter = 1;
        this._retainedDataPrefix = `retained_${pageId}_`;

        this._consumeAttributeEvent = this._consumeAttributeEvent.bind(this);
        this.getNextId = this.getNextId.bind(this);
        this.getNextCount = this.getNextCount.bind(this);

        // Consume every attribute change event.
        editingDoc.listenTo( editingDoc.roots.first, 'change:attributes', this._consumeAttributeEvent );
    }

    getNextCount() {
        return this._idCounter++;
    }

    getNextId() {
        return `${this._retainedDataPrefix}${this._idCounter++}`;
    }

    _consumeAttributeEvent( evt, elem ) {
        // Check for retained data ID and only handle ones that match our prefix
        const retainedDataId = elem.getAttribute( RETAINED_DATA_ATTRIBUTE );
        if ( retainedDataId && retainedDataId.startsWith( this._retainedDataPrefix ) ) {
            const id = parseInt( retainedDataId.split( this._retainedDataPrefix ).pop() );
            // If retained data ID is larger than current count, set count to data ID + 1
            // Otherwise, keep the current count
            this._idCounter = Math.max( id + 1, this._idCounter );
        }

        // Check for ID and handle numeric ones so we don't collide with existing ones
        const id = elem.getAttribute( 'id' );
        if ( id && !isNaN( id ) ) {
            this._idCounter = Math.max( parseInt(id) + 1, this._idCounter );
        }
    }
}
