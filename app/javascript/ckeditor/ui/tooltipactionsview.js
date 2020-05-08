/**
 * @license Copyright (c) 2003-2020, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.md or https://ckeditor.com/legal/ckeditor-oss-license
 */

/**
 * @module tooltip/ui/tooltipactionsview
 */

import View from '@ckeditor/ckeditor5-ui/src/view';
import ViewCollection from '@ckeditor/ckeditor5-ui/src/viewcollection';

import ButtonView from '@ckeditor/ckeditor5-ui/src/button/buttonview';

import FocusTracker from '@ckeditor/ckeditor5-utils/src/focustracker';
import FocusCycler from '@ckeditor/ckeditor5-ui/src/focuscycler';
import KeystrokeHandler from '@ckeditor/ckeditor5-utils/src/keystrokehandler';

//import removeTooltipIcon from '../theme/icons/removetooltip.svg';
import removeTooltipIcon from '@ckeditor/ckeditor5-link/theme/icons/unlink.svg';
import pencilIcon from '@ckeditor/ckeditor5-core/theme/icons/pencil.svg';
import '../theme/tooltipactions.css';

/**
 * The tooltip actions view class. This view displays the tooltip preview, allows
 * removeTooltiping or editing the tooltip.
 *
 * @extends module:ui/view~View
 */
export default class TooltipActionsView extends View {
	/**
	 * @inheritDoc
	 */
	constructor( locale ) {
		super( locale );

		const t = locale.t;

		/**
		 * Tracks information about DOM focus in the actions.
		 *
		 * @readonly
		 * @member {module:utils/focustracker~FocusTracker}
		 */
		this.focusTracker = new FocusTracker();

		/**
		 * An instance of the {@tooltip module:utils/keystrokehandler~KeystrokeHandler}.
		 *
		 * @readonly
		 * @member {module:utils/keystrokehandler~KeystrokeHandler}
		 */
		this.keystrokes = new KeystrokeHandler();

		/**
		 * The title preview view.
		 *
		 * @member {module:ui/view~View}
		 */
		this.previewButtonView = this._createPreviewButton();

		/**
		 * The removeTooltip button view.
		 *
		 * @member {module:ui/button/buttonview~ButtonView}
		 */
		this.removeTooltipButtonView = this._createButton( t( 'Remove Tooltip' ), removeTooltipIcon, 'removeTooltip' );

		/**
		 * The edit tooltip button view.
		 *
		 * @member {module:ui/button/buttonview~ButtonView}
		 */
		this.editButtonView = this._createButton( t( 'Edit tooltip' ), pencilIcon, 'edit' );

		/**
		 * The value of the "title" attribute of the tooltip to use in the {@tooltip #previewButtonView}.
		 *
		 * @observable
		 * @member {String}
		 */
		this.set( 'title' );

		/**
		 * A collection of views that can be focused in the view.
		 *
		 * @readonly
		 * @protected
		 * @member {module:ui/viewcollection~ViewCollection}
		 */
		this._focusables = new ViewCollection();

		/**
		 * Helps cycling over {@tooltip #_focusables} in the view.
		 *
		 * @readonly
		 * @protected
		 * @member {module:ui/focuscycler~FocusCycler}
		 */
		this._focusCycler = new FocusCycler( {
			focusables: this._focusables,
			focusTracker: this.focusTracker,
			keystrokeHandler: this.keystrokes,
			actions: {
				// Navigate fields backwards using the Shift + Tab keystroke.
				focusPrevious: 'shift + tab',

				// Navigate fields forwards using the Tab key.
				focusNext: 'tab'
			}
		} );

		this.setTemplate( {
			tag: 'div',

			attributes: {
				class: [
					'ck',
					'ck-tooltip-actions',
				],

				// https://github.com/ckeditor/ckeditor5-link/issues/90
				tabindex: '-1'
			},

			children: [
				this.previewButtonView,
				this.editButtonView,
				this.removeTooltipButtonView
			]
		} );
	}

	/**
	 * @inheritDoc
	 */
	render() {
		super.render();

		const childViews = [
			this.previewButtonView,
			this.editButtonView,
			this.removeTooltipButtonView
		];

		childViews.forEach( v => {
			// Register the view as focusable.
			this._focusables.add( v );

			// Register the view in the focus tracker.
			this.focusTracker.add( v.element );
		} );

		// Start listening for the keystrokes coming from #element.
		this.keystrokes.listenTo( this.element );
	}

	/**
	 * Focuses the fist {@tooltip #_focusables} in the actions.
	 */
	focus() {
		this._focusCycler.focusFirst();
	}

	/**
	 * Creates a button view.
	 *
	 * @private
	 * @param {String} label The button label.
	 * @param {String} icon The button icon.
	 * @param {String} [eventName] An event name that the `ButtonView#execute` event will be delegated to.
	 * @returns {module:ui/button/buttonview~ButtonView} The button view instance.
	 */
	_createButton( label, icon, eventName ) {
		const button = new ButtonView( this.locale );

		button.set( {
			label,
			icon,
			tooltip: true
		} );

		button.delegate( 'execute' ).to( this, eventName );

		return button;
	}

	/**
	 * Creates a tooltip title preview button.
	 *
	 * @private
	 * @returns {module:ui/button/buttonview~ButtonView} The button view instance.
	 */
	_createPreviewButton() {
		const button = new ButtonView( this.locale );
		const bind = this.bindTemplate;
		const t = this.t;

		button.set( {
			withText: true
		} );

		button.extendTemplate( {
			attributes: {
				class: [
					'ck',
					'ck-tooltip-actions__preview'
				],
				title: bind.to( 'title', title => title ),
				target: '_blank',
				rel: 'noopener noreferrer'
			}
		} );

		button.bind( 'label' ).to( this, 'title', title => {
			return title || t( 'This tooltip has no text' );
		} );

		button.bind( 'isEnabled' ).to( this, 'title', title => !!title );

		button.template.tag = 'a';
		button.template.eventListeners = {};

		return button;
	}
}

/**
 * Fired when the {@tooltip #editButtonView} is clicked.
 *
 * @event edit
 */

/**
 * Fired when the {@tooltip #removeTooltipButtonView} is clicked.
 *
 * @event removeTooltip
 */
