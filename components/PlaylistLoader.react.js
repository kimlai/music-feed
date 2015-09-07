var React = require('react');

module.exports = React.createClass({
    render: function () {
        var placeholders = [];
        for (var i=0; i < 10; i++) {
            placeholders.push(
                <div className="track" key={i}>
                    <div className="track-info-container">
                        <img src="/images/placeholder.jpg" />
                    </div>
                    <div className="progress-bar">
                        <div className="outer" />
                    </div>
                </div>
            );
        }

        return (
            <div>
                {placeholders}
            </div>
        );
    }
});
