import React from "react"
import PropTypes from "prop-types"
class QuestionForm extends React.Component {
  state = {
    question: this.props.question
  }

  handleSubmit(e) {
    e.preventDefault();

    // Read the form data
    const form = e.target;
    const formData = new FormData(form);

    fetch("/questions", {
      method: form.method,
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      },
    }).then((data) => {
      if (data.ok) {
        const result = data.json();
        console.log("result", result)
        return result
      }
      throw new Error("some kind of error, wish I knew");
    })
  }

  handleQuestionChange(event) {
    this.setState({ question: event.target.value });
  }

  render () {
    return (
      <form method="post" onSubmit={this.handleSubmit}>
        <label>
          Ask a question: <textarea name="question" id="question" value={this.state.question} onChange={this.handleQuestionChange.bind(this)}></textarea>
        </label>

        <button type="submit" id="ask-button" style={{display: this.props.answer === undefined ? 'block' : 'none' }}>
          Ask question
        </button>
      </form>
    );
  }
}

QuestionForm.propTypes = {
  answer: PropTypes.string
};
export default QuestionForm
