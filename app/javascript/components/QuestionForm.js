import React from "react"
import PropTypes from "prop-types"
class QuestionForm extends React.Component {
  state = {
    question: this.props.question
  }

  handleSubmit(e) {
    // Prevent the browser from reloading the page
    e.preventDefault();

    // Read the form data
    const form = e.target;
    const formData = new FormData(form);

    // You can pass formData as a fetch body directly:
    fetch('/some-api', { method: form.method, body: formData });

    // Or you can work with it as a plain object:
    const formJson = Object.fromEntries(formData.entries());
    console.log(formJson);
  }

  handleQuestionChange(event) {
    this.setState({ question: event.target.value });
  }

  render () {
    return (
      // do I need action="/" ? do I want that? I think so - the
      // QuestionsController will just be the root.
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
