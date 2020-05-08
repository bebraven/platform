import Plugin from '@ckeditor/ckeditor5-core/src/plugin';
import Widget from '@ckeditor/ckeditor5-widget/src/widget';

import AddTooltipCommand from './addtooltipcommand';
import RemoveTooltipCommand from './removetooltipcommand';


export default class TooltipEditing extends Plugin {
    static get requires() {
        return [ ];
    }

    init() {
        this._defineSchema();
        this._defineConverters();
    }

    _defineSchema() {
        const schema = this.editor.model.schema;

        schema.extend( '$text', { allowAttributes: 'tooltipText' } );
    }

    _defineConverters() {
        const editor = this.editor;
        const conversion = editor.conversion;

        conversion.for( 'dataDowncast' )
            .attributeToElement( { model: 'tooltipText', view: createTooltipElement } );

        conversion.for( 'editingDowncast' )
            .attributeToElement( { model: 'tooltipText', view: ( title, writer ) => {
                return createTooltipElement( title, writer );
            } } );

        conversion.for( 'upcast' )
            .elementToAttribute( {
                view: {
                    name: 'span',
                    classes: [ 'has-tooltip' ],
                    attributes: {
                        title: true,
                    }
                },
                model: {
                    key: 'tooltipText',
                    value: viewElement => viewElement.getAttribute( 'title' )
                }
            } );

        editor.commands.add( 'addTooltip', new AddTooltipCommand( editor ) );
        editor.commands.add( 'removeTooltip', new RemoveTooltipCommand( editor ) );
    }
}

function createTooltipElement( title, writer ) {
    // Priority 5 - https://github.com/ckeditor/ckeditor5-link/issues/121.
    const tooltipElement = writer.createAttributeElement( 'span', { 'title': title, 'class': 'has-tooltip' }, { priority: 5 } );
    writer.setCustomProperty( 'tooltip', true, tooltipElement );

    return tooltipElement;
}
