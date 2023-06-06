import React, { useState } from "react"
import PropTypes from "prop-types"
function Answer(props) {
  return (
    <React.Fragment>
      <p id="answer-container" style={{display: props.answer === undefined ? 'none' : 'block' }}>
        <strong>Answer:</strong> <span id="answer">{props.answer}</span>
      </p>
      <div className="buttons" style={{display: props.answer === undefined ? 'none' : 'block' }}>
        // this button doesn't interrupt the typing animation, but it should.
        <button id="ask-another-button" onClick={props.reset}>Ask another question</button>
      </div>
    </React.Fragment>
  );
}

Answer.propTypes = {
  answer: PropTypes.string
};
export default Answer
