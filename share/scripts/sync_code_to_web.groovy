/*
 * Copyright 2011 gitblit.com.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import com.gitblit.GitBlit
import com.gitblit.Keys
import com.gitblit.models.RepositoryModel
import com.gitblit.models.TeamModel
import com.gitblit.models.UserModel
import com.gitblit.utils.JGitUtils
import java.text.SimpleDateFormat

import org.eclipse.jgit.api.Status;
import org.eclipse.jgit.api.errors.JGitInternalException;
import org.eclipse.jgit.diff.DiffEntry;
import org.eclipse.jgit.diff.DiffFormatter;
import org.eclipse.jgit.diff.RawTextComparator;
import org.eclipse.jgit.diff.DiffEntry.ChangeType;
import org.eclipse.jgit.lib.Constants;
import org.eclipse.jgit.lib.IndexDiff;
import org.eclipse.jgit.lib.ObjectId;
import org.eclipse.jgit.lib.Repository
import org.eclipse.jgit.lib.Config
import org.eclipse.jgit.patch.FileHeader;
import org.eclipse.jgit.revwalk.RevCommit
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.transport.ReceiveCommand
import org.eclipse.jgit.transport.ReceiveCommand.Result
import org.eclipse.jgit.treewalk.FileTreeIterator;
import org.eclipse.jgit.treewalk.EmptyTreeIterator;
import org.eclipse.jgit.treewalk.CanonicalTreeParser;
import org.eclipse.jgit.util.io.DisabledOutputStream;
import org.slf4j.Logger
import groovy.xml.MarkupBuilder

import java.io.IOException;
import java.security.MessageDigest

//import groovy.net.http.HTTPBuilder
import groovy.json.JsonBuilder


/**
 * Sample Gitblit Post-Receive Hook: jenkins
 *
 * The Post-Receive hook is executed AFTER the pushed commits have been applied
 * to the Git repository.  This is the appropriate point to trigger an
 * integration build or to send a notification.
 *
 * This script is only executed when pushing to *Gitblit*, not to other Git
 * tooling you may be using.
 *
 * If this script is specified in *groovy.postReceiveScripts* of gitblit.properties
 * or web.xml then it will be executed by any repository when it receives a
 * push.  If you choose to share your script then you may have to consider
 * tailoring control-flow based on repository access restrictions.
 *
 * Scripts may also be specified per-repository in the repository settings page.
 * Shared scripts will be excluded from this list of available scripts.
 *
 * This script is dynamically reloaded and it is executed within it's own
 * exception handler so it will not crash another script nor crash Gitblit.
 *
 * Bound Variables:
 *  gitblit			Gitblit Server	 			com.gitblit.GitBlit
 *  repository		Gitblit Repository			com.gitblit.models.RepositoryModel
 *  receivePack		JGit Receive Pack			org.eclipse.jgit.transport.ReceivePack
 *  user			Gitblit User				com.gitblit.models.UserModel
 *  commands		JGit commands 				Collection<org.eclipse.jgit.transport.ReceiveCommand>
 *	url				Base url for Gitblit		String
 *  logger			Logs messages to Gitblit 	org.slf4j.Logger
 *  clientLogger	Logs messages to Git client	com.gitblit.utils.ClientLogger
 *
 * Accessing Gitblit Custom Fields:
 *   def myCustomField = repository.customFields.myCustomField
 *
 */
// Indicate we have started the script


com.gitblit.models.UserModel userModel = user

// Indicate we have started the script
logger.info("sync_code_to_web hook triggered by ${user.username} for ${repository.name}")

/*
 * Primitive email notification.
 * This requires the mail settings to be properly configured in Gitblit.
 */

Repository r = gitblit.getRepository(repository.name)

// reuse existing repository config settings, if available
Config config = r.getConfig()
def mailinglist = config.getString('hooks', null, 'mailinglist')
def emailprefix = config.getString('hooks', null, 'emailprefix')

def toAddresses = []
if (emailprefix == null) {
    emailprefix = '[Gitblit]'
}

if (mailinglist != null) {
    def addrs = mailinglist.split(/(,|\s)/)
    toAddresses.addAll(addrs)
}

toAddresses.addAll(GitBlit.getStrings(Keys.mail.mailingLists))

// add all team mailing lists
def teams = gitblit.getRepositoryTeams(repository)
for (team in teams) {
    TeamModel model = gitblit.getTeamModel(team)
    if (model.mailingLists) {
        toAddresses.addAll(model.mailingLists)
    }
}

// add all mailing lists for the repository
toAddresses.addAll(repository.mailingLists)


def repo = repository.name
def summaryUrl = url + "/summary?r=$repo"
def baseCommitUrl = url + "/commit?r=$repo&h="
def baseBlobDiffUrl = url + "/blobdiff/?r=$repo&h="
def baseCommitDiffUrl = url + "/commitdiff/?r=$repo&h="
def forwardSlashChar = gitblit.getString(Keys.web.forwardSlashCharacter, '/')

if (gitblit.getBoolean(Keys.web.mountParameters, true)) {
    repo = repo.replace('/', forwardSlashChar).replace('/', '%2F')
    summaryUrl = url + "/summary/$repo"
    baseCommitUrl = url + "/commit/$repo/"
    baseBlobDiffUrl = url + "/blobdiff/$repo/"
    baseCommitDiffUrl = url + "/commitdiff/$repo/"
}


class GitPushResolver  {
    Repository repository
    def url
    def baseCommitUrl
    def baseCommitDiffUrl
    def baseBlobDiffUrl
    def mountParameters
    def forwardSlashChar
    def includeGravatar
    def shortCommitIdLength
    def commitCount = 0
    def commands

    def commitUrl(RevCommit commit) {
        "${baseCommitUrl}$commit.id.name"
    }

    def commitDiffUrl(RevCommit commit) {
        "${baseCommitDiffUrl}$commit.id.name"
    }

    def encoded(String path) {
        path.replace('/', forwardSlashChar).replace('/', '%2F')
    }

    def blobDiffUrl(objectId, path) {
        if (mountParameters) {
            // REST style
            "${baseBlobDiffUrl}${objectId.name()}/${encoded(path)}"
        } else {
            "${baseBlobDiffUrl}${objectId.name()}&f=${path}"
        }

    }


//    for (commit in commits) {
//        def command = commands[-1]
//        def commits = JGitUtils.getRevLog(repository, command.oldId.name, command.newId.name).reverse()
//        def commit = commits[-1]
//        def abbreviated = repository.newObjectReader().abbreviate(commit.id, shortCommitIdLength).name()
//        def author = commit.authorIdent.name
//        def message = commit.shortMessage
//        def email = commit.authorIdent.emailAddress
//        email.trim().toLowerCase()
//    }



    def write() {

                for (command in commands) {
                    def ref = command.refName
                    def refType = 'Branch'
                    if (ref.startsWith('refs/heads/')) {
                        ref  = command.refName.substring('refs/heads/'.length())
                    } else if (ref.startsWith('refs/tags/')) {
                        ref  = command.refName.substring('refs/tags/'.length())
                        refType = 'Tag'
                    }

                    switch (command.type) {
                        case ReceiveCommand.Type.CREATE:
							def commits = JGitUtils.getRevLog(repository, command.oldId.name, command.newId.name).reverse()
							commitCount += commits.size()
							if (refType == 'Branch') {
								// new branch

							} else {
								// new tag

							}
                            break
                        case ReceiveCommand.Type.UPDATE:
                            def commits = JGitUtils.getRevLog(repository, command.oldId.name, command.newId.name).reverse()
                            commitCount += commits.size()
                            // fast-forward branch commits table
                            // Write header

                            break
                        case ReceiveCommand.Type.UPDATE_NONFASTFORWARD:
                            def commits = JGitUtils.getRevLog(repository, command.oldId.name, command.newId.name).reverse()
                            commitCount += commits.size()
                            // non-fast-forward branch commits table
                            // Write header
                            break
                        case ReceiveCommand.Type.DELETE:
                            // deleted branch/tag
                            break
                        default:
                            break
                    }
               }

    }



}



def gpr = new GitPushResolver()
gpr.repository = r
gpr.baseCommitUrl = baseCommitUrl
gpr.baseBlobDiffUrl = baseBlobDiffUrl
gpr.baseCommitDiffUrl = baseCommitDiffUrl
gpr.forwardSlashChar = forwardSlashChar
gpr.commands = commands
gpr.url = url
gpr.mountParameters = GitBlit.getBoolean(Keys.web.mountParameters, true)
gpr.includeGravatar = GitBlit.getBoolean(Keys.web.allowGravatar, true)
gpr.shortCommitIdLength = GitBlit.getInteger(Keys.web.shortCommitIdLength, 8)


def command = commands[-1]
                    def ref = command.refName
                    def refType = 'Branch'
                    if (ref.startsWith('refs/heads/')) {
                        ref  = command.refName.substring('refs/heads/'.length())
                    } else if (ref.startsWith('refs/tags/')) {
                        ref  = command.refName.substring('refs/tags/'.length())
                        refType = 'Tag'
                    }


def commits = JGitUtils.getRevLog(r, command.oldId.name, command.newId.name).reverse()
def commit = commits[-1]
def CommitAuthor = commit.authorIdent.name
def CommitMessage = commit.shortMessage
def CommitEmail = commit.authorIdent.emailAddress


// close the repository reference
r.close()

// tell Gitblit to send the message (Gitblit filters duplicate addresses)
def repositoryName = repository.name.substring(0, repository.name.length() - 4)
//gitblit.sendHtmlMail("${emailprefix} ${userModel.displayName} pushed ${gpr.commitCount} commits => $repositoryName")


//Process p="/data/scripts/test_auto_git_pull.sh $url ${repository.name} ${user.username} $refType $ref ${command.type}".execute();

Process p="/data/scripts/test_auto_git_pull.sh $url ${repository.name} ${user.username}  ${emailprefix}  $refType $ref  ${command.type}  ${CommitAuthor} ${CommitEmail} ${CommitMessage} ".execute();


static createAuthToken(String username, String password){
    def url = new URL("https://www.google.com/accounts/ClientLogin")
    def connection = url.openConnection()

    def queryString = "Email=${username}&Passwd=${password}" +
                      "&service=finance&source=company-groovyfinance-1.0"

    def returnMessage = processRequest(connection, queryString)

    if(returnMessage != "Error"){
        //the authentication token
        return returnMessage.split(/Auth=/)[1].trim()
    }
}


static String processRequest(connection, dataString){
    connection.setRequestMethod("POST")
    connection.doOutput = true
    Writer writer = new OutputStreamWriter(connection.outputStream)
    writer.write(dataString)
    writer.flush()
    writer.close()
    connection.connect()

    if (connection.responseCode == 200 || connection.responseCode == 201)
        return connection.content.text

    return "Error"
}

def GitPush = ['url':url, 'repository_name':repository.name, 'username':user.username, 'ref_type':refType, 'ref':ref, 'command_type':command.type, 'commit_author':CommitAuthor, 'commit_email':CommitEmail, 'commit_message':CommitMessage]
def json = new groovy.json.JsonBuilder(GitPush)
def JsonString = json.toString()


def url = new URL("http://develop.spunkmars.net:5001/VCS/Gitblit.Push")
def connection = url.openConnection()
def queryString = "login_username=admin&login_password=admin123&git_push_info=${URLEncoder.encode(JsonString)}"
//def queryString = "login_username=admin&login_password=admin123&git_push_info=${JsonString}"

processRequest(connection, queryString)

/*

json = new groovy.json.JsonBuilder()

json.messages() {
    message {
        id     23
        sender 'me'
        text   'some text'
    }
    message {
        id     24
        sender 'me'
        text   'some other text'
    }
}

assert json.toString() ==
       '{"messages":{"message":{"id":24,"sender":"me","text":"some other text"}}}'


-----------------------------
def map1 = ['one':1, 'two':2]
json = new groovy.json.JsonBuilder(map1)
def JsonString = json.toString()



*/
