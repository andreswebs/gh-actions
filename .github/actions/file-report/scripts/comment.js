const fs = require('node:fs');

const {
  ENV_NAME,
  SOURCE_TXT,
  COMMENT_HEADER,
  SUMMARY_HEADER,
} = process.env;

const text = fs.readFileSync(SOURCE_TXT, 'utf8');

const commentHeader = COMMENT_HEADER ? COMMENT_HEADER : 'Environment Report';
const summaryHeader = SUMMARY_HEADER ? SUMMARY_HEADER : 'Show Report';

const maxGitHubBodyCharacters = 65536;
const maxBodyCharacters = maxGitHubBodyCharacters - 1536;

function chunkSubstr(str, size) {
  const numChunks = Math.ceil(str.length / size);
  const chunks = [];
  for (let i = 0, o = 0; i < numChunks; i++, o += size) {
    chunks.push(str.substring(o, o + size));
  }
  return chunks;
}

const chunks = chunkSubstr(text, maxBodyCharacters);

async function githubComment({ github, context }) {

  const envComment = ENV_NAME ? ` - ${ENV_NAME}` : '';

  let output = '';

  console.log('TEST 1');

  if (chunks.length) {

    console.log('TEST 2');

    output += `## ${commentHeader}${envComment}\n\n`;

    await github.rest.issues.createComment({
      issue_number: context.issue.number,
      owner: context.repo.owner,
      repo: context.repo.repo,
      body: output
    });

    for (let i = 0; i < chunks.length; i++) {
      output = `## ${envComment ? envComment + ' -' : ''}Part ${i + 1} of ${chunks.length}\n\n`;
      output += '<details>\n\n';
      output += `<summary>${summaryHeader}</summary>\n\n`;
      output += '```\n\n';
      output += `${chunks[i]}\n\n`;
      output += '```\n\n';
      output += '</details>\n\n';
      output += `**Triggered by @${context.actor}, on Event \`${context.eventName}\`**\n`;

      await github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: output
      });
    }

  }

}

module.exports = githubComment;
