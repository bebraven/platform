import React from "react";
import { slide as Menu } from "react-burger-menu";

export default class Sidebar extends React.Component {
    constructor( props ) {
        super( props );

        this.customContents = this.props.customContents.map((customContent) =>
            <a
                key={customContent.id}
                className="menu-item"
                href={"/custom_contents/" + customContent.id + "/edit"}
            >
                {customContent.title || "unnamed"}
            </a>
        );

    }

    render () {
        return (
            <Menu
                bodyClass={"ck-inspector-body-collapsed"}
            >
                {this.customContents}
            </Menu>
        );
    }
}
