import React from "react"
import PropTypes from "prop-types"
import Answer from "./Answer"

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
        return result
      }
      throw new Error("some kind of error, wish I knew");
    }).then((response) => {
      this.setState({ answer: response.answer })
    })
  }

  handleQuestionChange(event) {
    this.setState({ question: event.target.value });
  }

  render () {
    return (
      <React.Fragment>
        <form method="post" onSubmit={this.handleSubmit.bind(this)}>
          <label>
            Ask a question: <textarea name="question" id="question" value={this.state.question} onChange={this.handleQuestionChange.bind(this)}></textarea>
          </label>

          <button type="submit" id="ask-button" style={{display: this.state.answer === undefined ? 'block' : 'none' }}>
            Ask question
          </button>
        </form>

        well, this thing isn't re-rendering, and it's clearly because I don't know how to use react.
        maybe try this? https://react.dev/learn/passing-data-deeply-with-context
        <Answer answer={this.state.answer}/>

        <p style={{display: this.state.answer === undefined ? 'none' : 'block' }}>
          {this.state.answer}
        </p>
      </React.Fragment>
    );
  }
}

QuestionForm.propTypes = {
  question: PropTypes.string,
  answer: PropTypes.string,
};
export default QuestionForm
