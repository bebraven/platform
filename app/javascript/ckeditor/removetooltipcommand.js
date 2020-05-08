/**
 * @license Copyright (c) 2003-2020, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.md or https://ckeditor.com/legal/ckeditor-oss-license
 */

/**
 * @module tooltip/removetooltipcommand
 */

import Command from '@ckeditor/ckeditor5-core/src/command';
import findTooltipRange from './findtooltiprange';

/**
 * The removeTooltip command. It is used by the {@tooltip module:tooltip/tooltip~Tooltip tooltip plugin}.
 *
 * @extends module:core/command~Command
 */
export default class RemoveTooltipCommand extends Command {
	/**
	 * @inheritDoc
	 */
	refresh() {
		this.isEnabled = this.editor.model.document.selection.hasAttribute( 'tooltipText' );
	}

	/**
	 * Executes the command.
	 *
	 * When the selection is collapsed, it removes the `tooltipText` attribute from each node with the same `tooltipText` attribute value.
	 * When the selection is non-collapsed, it removes the `tooltipText` attribute from each node in selected ranges.
	 *
	 * # Decorators
	 *
	 * If {@tooltip module:tooltip/tooltip~TooltipConfig#decorators `config.tooltip.decorators`} is specified,
	 * all configured decorators are removed together with the `tooltipText` attribute.
	 *
	 * @fires execute
	 */
	execute() {
		const editor = this.editor;
		const model = this.editor.model;
		const selection = model.document.selection;
		const addTooltipCommand = editor.commands.get( 'addTooltip' );

		model.change( writer => {
			// Get ranges to remove tooltip from.
			const rangesToRemove = selection.isCollapsed ?
				[ findTooltipRange( selection.getFirstPosition(), selection.getAttribute( 'tooltipText' ), model ) ] : selection.getRanges();

			// Remove `tooltipText` attribute from specified ranges.
			for ( const range of rangesToRemove ) {
				writer.removeAttribute( 'tooltipText', range );
				// If there are registered custom attributes, then remove them during removeTooltip.
				if ( addTooltipCommand ) {
					for ( const manualDecorator of addTooltipCommand.manualDecorators ) {
						writer.removeAttribute( manualDecorator.id, range );
					}
				}
			}
		} );
	}
}
