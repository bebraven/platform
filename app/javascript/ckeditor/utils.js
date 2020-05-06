// See https://stackoverflow.com/questions/59040225/how-do-i-make-an-editable-label-for-an-input-within-a-ckeditor5-widget
// and https://github.com/ckeditor/ckeditor5-core/compare/proto/input-widget#diff-44ca1561ce575490eac0d660407d5144R239
export function preventCKEditorHandling( domElement, editor ) {
    // Prevent the editor from listening on below events in order to stop rendering selection.
    domElement.addEventListener( 'click', stopEventPropagationAndHackRendererFocus, { capture: true } );
    domElement.addEventListener( 'mousedown', stopEventPropagationAndHackRendererFocus, { capture: true } );
    domElement.addEventListener( 'focus', stopEventPropagationAndHackRendererFocus, { capture: true } );

    // Prevents TAB handling or other editor keys listeners which might be executed on editors selection.
    domElement.addEventListener( 'keydown', stopEventPropagationAndHackRendererFocus, { capture: true } );

    function stopEventPropagationAndHackRendererFocus( evt ) {
        evt.stopPropagation();
        // This prevents rendering changed view selection thus preventing to changing DOM selection while inside a widget.
        editor.editing.view._renderer.isFocused = false;
    }
}

// Return the model element that is a parent of modelElement, with the model
// name ancestorName. If there are multiple matching elements, return only the
// topmost one. modelElement can also be a `Postition` inside the model.
export function getNamedAncestor( ancestorName, modelElement ) {
    return modelElement.getAncestors().filter( x => { return x.name == ancestorName } )[0];
}

// Return the model element that is a child or sibling of modelElement, with the model
// name ancestorName. Returns the first result in order of:
// * Children, in DOM order
// * Siblings, in DOM order
// * undefined
export function getNamedChildOrSibling( elementName, modelElement ) {
    function filterByName( elementName, modelElement ) {
        return Array.from(modelElement.getChildren()).filter(
                x => { return x.name == elementName }
        )[0];
    }

    let firstMatch;
    if ( firstMatch = filterByName( elementName, modelElement ) ) {
        return firstMatch;
    }

    return filterByName( elementName, modelElement.parent );
}

/**
 * Tries to find position ancestors that allows to insert given node.
 * It starts searching from the given position and goes node by node to the top of the model tree
 * as long as top-most ancestor won't be reached. This explicitly ignores isLimit/isObject, unlike
 * findAllowedParent.
 *
 * Modified from https://github.com/ckeditor/ckeditor5-engine/blob/373a0fb/src/model/schema.js#L709.
 *
 * @params schema.
 * @params {module:engine/model/position~Position} position Position from searching will start.
 * @params {module:engine/model/node~Node|String} node Node for which allowed parent should be found or its name.
 * @returns {module:engine/model/element~Element|null} element Allowed parent or null if nothing was found.
 */
export function findAllowedParentIgnoreLimit( schema, position, node ) {
    let parent = position.parent;

    while ( parent ) {
        if ( schema.checkChild( parent, node ) ) {
            return parent;
        }

        parent = parent.parent;
    }

    return null;
}
