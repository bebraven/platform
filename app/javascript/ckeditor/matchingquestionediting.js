import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import { toWidget, toWidgetEditable } from '@ckeditor/ckeditor5-widget/src/utils';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';
import InsertMatchingQuestionCommand from './insertmatchingquestioncommand';
import InsertMatchingTableRow from './insertmatchingtablerowcommand';

export default class MatchingQuestionEditing extends Plugin {
    static get requires() {
        return [ Widget ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();

        this.editor.commands.add( 'insertMatchingQuestion', new InsertMatchingQuestionCommand( this.editor ) );
        this.editor.commands.add( 'insertMatchingTableRow', new InsertMatchingTableRow( this.editor ) );

        // Override the default 'enter' key behavior for matching table cells.
        // Default behavior is to insert a new paragraph inside the cell, but the behavior we want
        // is to insert a new row below the current row.
        this.listenTo( this.editor.editing.view.document, 'enter', ( evt, data ) => {
            const positionParent = this.editor.model.document.selection.getLastPosition().parent;
            if ( positionParent.name == 'matchingTableCell' ) {
                this.editor.execute( 'insertMatchingTableRow' )
                data.preventDefault();
                evt.stop();
            }
        });
    }

    /**
     * Example valid structure:
     *
     * <question>
     *   <questionTitle>$text</questionTitle>
     *   <questionBody>$block</questionBody>
     *   <matchingTable>
     *     <matchingTableHeader>
     *       <matchingTableHeaderCell>$text</matchingTableHeaderCell>
     *     </matchingTableHeader>
     *     <matchingTableBody>
     *       <matchingTableRow>
     *         <matchingTableCell>$block</matchingTableCell>
     *       </matchingTableRow>
     *     </matchingTableBody>
     *   </matchingTable>
     *   <doneButton/>
     * </question>
     */
    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.register( 'matchingTable', {
            isObject: true,
            allowIn: 'question',
        } );

        schema.register( 'matchingTableHeader', {
            isLimit: true,
            allowIn: 'matchingTable'
        } );

        schema.register( 'matchingTableBody', {
            isLimit: true,
            allowIn: 'matchingTable'
        } );

        schema.register( 'matchingTableRow', {
            allowIn: [ 'matchingTableHeader', 'matchingTableBody' ],
        } );

        schema.register( 'matchingTableHeaderCell', {
            isObject: true,
            isInline: true,
            allowIn: 'matchingTableRow',
            allowContentOf: '$block',
        } );

        schema.register( 'matchingTableCell', {
            isObject: true,
            isInline: true,
            allowIn: 'matchingTableRow',
            allowContentOf: [ '$root', '$block' ]
        } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;
        const { editing, data, model } = editor;

        // <matchingTable> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'table',
                classes: ['sort-to-match', 'no-zebra']
            },
            model: 'matchingTable'
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'matchingTable',
            view: ( modelElement, viewWriter ) => {
                return viewWriter.createEditableElement( 'table', {
                    'class': 'sort-to-match no-zebra'
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'matchingTable',
            view: ( modelElement, viewWriter ) => {
                const table = viewWriter.createEditableElement( 'table', {
                    'class': 'sort-to-match no-zebra'
                } );
                return toWidgetEditable( table, viewWriter, { label: 'matching game table', hasSelectionHandle: true } );
            }
        } );

        // <matchingTableHeader> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'thead'
            },
            model: 'matchingTableHeader'
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'matchingTableHeader',
            view: {
                name: 'thead'
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'matchingTableHeader',
            view: ( modelElement, viewWriter ) => {
                const head = viewWriter.createContainerElement( 'thead' );
                return toWidget( head, viewWriter );
            }
        } );

        // <matchingTableBody> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'tbody'
            },
            model: 'matchingTableBody'
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'matchingTableBody',
            view: {
                name: 'tbody'
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'matchingTableBody',
            view: ( modelElement, viewWriter ) => {
                const body = viewWriter.createContainerElement( 'tbody' );
                return toWidget( body, viewWriter );
            }
        } );

        // <matchingTableRow> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'tr',
            },
            model: ( viewElement, modelWriter ) => {
                const classes = viewElement.getAttribute( 'class' );
                return modelWriter.createElement( 'matchingTableRow', classes === undefined ? {} : {
                    'class': classes
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'matchingTableRow',
            view: ( modelElement, viewWriter ) => {
                const classes = modelElement.getAttribute( 'class' );
                return viewWriter.createContainerElement( 'tr', classes === undefined ? {} : {
                    'class': classes
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'matchingTableRow',
            view: ( modelElement, viewWriter ) => {
                const classes = modelElement.getAttribute( 'class' );
                const cell = viewWriter.createContainerElement( 'tr', classes === undefined ? {} : {
                    'class': classes
                });

                return toWidget( cell, viewWriter );
            }
        } );

        // <matchingTableHeaderCell> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'th',
            },
            model: ( viewElement, modelWriter ) => {
                const classes = viewElement.getAttribute( 'class' );
                return modelWriter.createElement( 'matchingTableHeaderCell', classes === undefined ? {} : {
                    'class': classes
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'matchingTableHeaderCell',
            view: ( modelElement, viewWriter ) => {
                const classes = modelElement.getAttribute( 'class' );
                return viewWriter.createEditableElement( 'th', classes === undefined ? {} : {
                    'class': classes
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'matchingTableHeaderCell',
            view: ( modelElement, viewWriter ) => {
                const classes = modelElement.getAttribute( 'class' );
                const cell = viewWriter.createEditableElement( 'th', classes === undefined ? {} : {
                    'class': classes
                });

                return toWidgetEditable( cell, viewWriter );
            }
        } );

        // <matchingTableCell> converters
        conversion.for( 'upcast' ).elementToElement( {
            view: {
                name: 'td',
            },
            model: ( viewElement, modelWriter ) => {
                const classes = viewElement.getAttribute( 'class' );
                return modelWriter.createElement( 'matchingTableCell', classes === undefined ? {} : {
                    'class': classes
                } );
            }
        } );
        conversion.for( 'dataDowncast' ).elementToElement( {
            model: 'matchingTableCell',
            view: ( modelElement, viewWriter ) => {
                const classes = modelElement.getAttribute( 'class' );
                return viewWriter.createEditableElement( 'td', classes === undefined ? {} : {
                    'class': classes
                } );
            }
        } );
        conversion.for( 'editingDowncast' ).elementToElement( {
            model: 'matchingTableCell',
            view: ( modelElement, viewWriter ) => {
                const classes = modelElement.getAttribute( 'class' );
                const cell = viewWriter.createEditableElement( 'td', classes === undefined ? {} : {
                    'class': classes
                });

                return toWidgetEditable( cell, viewWriter );
            }
        } );
    }
}
