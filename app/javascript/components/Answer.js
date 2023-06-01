import React, { useState } from "react"
import PropTypes from "prop-types"
function Answer(props) {
  return (
    <p style={{display: props.answer === undefined ? 'none' : 'block' }}>
      Answer: {props.answer}
    </p>
  );
}

Answer.propTypes = {
  answer: PropTypes.string
};
export default Answer
