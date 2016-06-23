import moment from 'moment';
import React from 'react';
import ReactDOM from 'react-dom';

class Alert extends React.Component {
    render () {
        return (
            <li className="alert-card">
              <h5 className="alert-card-header">
                <i className="fa fa-exclamation-triangle" aria-hidden="true"></i>
                {' '}{this.props.effect_name}
              </h5>
              <p className="alert-card-body">{this.props.header}</p>
              <p className="alert-card-footer"><small>Updated {moment(this.props.updated_at).fromNow()}</small></p>
            </li>
        );
    }
}

class Notice extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            expanded: false
        };
    }

    convertNewlineToBr(text) {
        return text.split("\n").map((line, index) => <span key={index}>{line}<br /></span>);
    }

    description () {
        let description_text = this.props.description;
        if (description_text === null) {
            return null;
        }
        if (description_text.length <= 500 || this.state.expanded) {
            return this.convertNewlineToBr(description_text);
        }
        let truncated = description_text.slice(0, 500) + '...';
        return (
            <span>
              {this.convertNewlineToBr(truncated)}
              <br />
              <button className="btn btn-link" onClick={() => { this.setState({expanded: true}); }}>
                <small>View More </small>
                <i className="fa fa-angle-right" aria-hidden="true"></i>
              </button>
            </span>
        );
    }

    render () {
        return (
            <li className="notice-card">
              <h5 className="notice-card-header">
                {' '}{this.props.header}
              </h5>
              <p className="notice-card-body no-overflow"><small>{this.description()}</small></p>
              <p className="notice-card-footer text-muted"><small>Updated {moment(this.props.updated_at).fromNow()}</small></p>
            </li>
        );
    }
}

class AlertList extends React.Component {
    render () {
        let alertNodes = this.props.alerts.map((alert) => {
            return React.createElement(this.props.alert_type, Object.assign({}, alert, {key: alert.id}));
        });
        return <ul>{alertNodes}</ul>;
    }
}

class AlertsModal extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            shown: false
        };
    }

    toggleState() {
        this.setState({shown: !this.state.shown});
    }

    /* Return a comma-separated list of all alert effect names, deduplicated. */
    displayAlertEffects() {
        return Array.from(
            new Set(this.props.alerts.concat(this.props.notices).map((alert) => alert.effect_name))
        ).join(', ');
    }

    closeButton () {
        return (
            <div className="col-xs-12">
              <button className="btn btn-secondary pull-right" onClick={this.toggleState.bind(this)}>
                <i className="fa fa-times-circle" aria-hidden="true"></i>
                {' '}Close
              </button>
            </div>
        );
    }

    header () {
        let route_name = this.props.route_type === 2 ? this.props.route : "Route " + this.props.route;
        return (
            <div className="schedule-alert-header">
              <div className="col-xs-2" dangerouslySetInnerHTML={{__html: this.props.route_image}}></div>
              <div className="col-xs-10">
                <h1 className="h4"><strong>Service Alerts & Notices</strong></h1>
                <h2 className="h5"><strong>{route_name}</strong></h2>
              </div>
            </div>
        );
    }

    alertSignupLink () {
        return (
            <div className="col-xs-12 schedules-link">
              <a href="/redirect/rider_tools%2Ft_alerts/">
                Sign up for T-Alerts to receive alerts for specific routes to your email or cell phone.
                <i className="fa fa-angle-right fa-pull-right" aria-hidden="true"></i>
              </a>
            </div>
        );
    }

    alerts () {
        if (this.props.alerts.length > 0) {
            return (
                <div>
                  <h3 className="h5 alert-list-header">Alerts</h3>
                  <AlertList alert_type={Alert} alerts={this.props.alerts} />
                </div>
            );
        }
        return null;
    }

    notices () {
        if (this.props.notices.length > 0) {
            return (
                <div>
                  <h3 className="h5 alert-list-header">Notices</h3>
                  <AlertList alert_type={Notice} alerts={this.props.notices} />
                </div>
            );
        }
        return null;
    }

    /* Moderately-sized hack to prevent the document from scrolling while the modal is shown. */
    setBodyScroll () {
        document.getElementsByTagName('body')[0].style.overflow = this.state.shown ? 'hidden' : 'scroll';
    }

    render() {
        this.setBodyScroll();
        // No alerts; don't show anything
        if (this.props.alerts.length === 0 && this.props.notices.length === 0) {
            return null;
        }
        // Render the modal window
        else if (this.state.shown) {
            return (
                <div className="alert-modal-wrapper">
                  <div className="col-xs-12 col-md-8 alert-modal">
                    {this.closeButton()}
                    {this.header()}
                    {this.alertSignupLink()}
                    {this.alerts()}
                    {this.notices()}
                  </div>
                </div>
            );
        }
        // Render the alerts links
        return (
            <button
                className="col-xs-12 col-md-6 btn btn-link schedules-link"
                onClick={this.toggleState.bind(this)}
            >
              <p>
                <small>
                  <i className="fa fa-exclamation-triangle alert-severe" aria-hidden="true"></i>
                  {' '}{this.displayAlertEffects()}
                </small>
              </p>
            </button>
        );
    }
}

export default function (options) {
    ReactDOM.render(<AlertsModal{...options}/>, document.getElementById('modal'));
};
