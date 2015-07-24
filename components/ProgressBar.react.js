var React = require('react');

module.exports = React.createClass({
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
