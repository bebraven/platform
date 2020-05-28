import Plugin from '@ckeditor/ckeditor5-core/src/plugin';

import { getViewImgFromWidget } from '@ckeditor/ckeditor5-image/src/image/utils';

/**
 * NOTE:
 * This file is meant to help with the transition period while we have old,
 * converted content that we need to still support. Old content has relative
 * image links, all of which are hosted on portal.bebraven.org. We can remove
 * this file once all relative image src attributes have been updated to point
 * to absolute URLs.
 */
const PORTAL_URL = 'https://portal.bebraven.org'

export default class PortalImageEditing extends Plugin {

    static get pluginName() {
        return 'PortalImageEditing';
    }

    init() {
        const editor = this.editor;
        const conversion = editor.conversion;

        // Add a custom converter to the end of the chain for CKEditor's builtin image editing downcast.
        conversion.for( 'editingDowncast' ).add( modelToViewAttributeConverter( 'src' ) );
    }
}

// See https://github.com/ckeditor/ckeditor5-image/blob/1b8369f8b380b1f3d107586b9bdfa43e0ab8a603/src/image/converters.js#L114
export function modelToViewAttributeConverter( attributeKey ) {
    return dispatcher => {
        dispatcher.on( `attribute:${ attributeKey }:image`, converter );
    };

    function converter( evt, data, conversionApi ) {
        const viewWriter = conversionApi.writer;
        const figure = conversionApi.mapper.toViewElement( data.item );
        const img = getViewImgFromWidget( figure );

        // If the src attribute starts with '/', prepend PORTAL_URL, so the image renders.
        if ( data.attributeKey === 'src' && data.attributeNewValue.startsWith( '/' ) ) {
            viewWriter.setAttribute( data.attributeKey, PORTAL_URL + data.attributeNewValue, img );
        } else if ( data.attributeNewValue !== null ) {
            viewWriter.setAttribute( data.attributeKey, data.attributeNewValue, img );
        } else {
            viewWriter.removeAttribute( data.attributeKey, img );
        }
    }
}

