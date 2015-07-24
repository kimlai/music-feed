var React = require('react');
var PureRenderMixin = require('react/addons').addons.PureRenderMixin;

module.exports = React.createClass({
    mixins: [PureRenderMixin],

    render: function () {
        var innerStyle = {
            width: this.props.progress + "%",
        };

        return (
            <div className="progress-bar outer">
                <div className="inner" style={innerStyle} />
            </div>
        );
    }
});
