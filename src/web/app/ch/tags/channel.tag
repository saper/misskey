<mk-channel>
	<header><a href={ CONFIG.chUrl }>Misskey Channels</a></header>
	<hr>
	<main if={ !fetching }>
		<h1>{ channel.title }</h1>
		<p if={ postsFetching }>読み込み中<mk-ellipsis/></p>
		<div if={ !postsFetching }>
			<p if={ posts == null }>まだ投稿がありません</p>
			<virtual if={ posts != null }>
				<mk-channel-post each={ posts.slice().reverse() } post={ this } form={ parent.refs.form }/>
			</virtual>
		</div>
		<hr>
		<mk-channel-form if={ SIGNIN } channel={ channel } ref="form"/>
		<div if={ !SIGNIN }>
			<p>参加するには<a href={ CONFIG.url }>ログインまたは新規登録</a>してください</p>
		</div>
		<hr>
		<footer>
			<small><a href={ CONFIG.url }>Misskey</a> ver { version } (葵 aoi)</small>
		</footer>
	</main>
	<style>
		:scope
			display block
			padding 8px

			> main
				> h1
					color #f00
	</style>
	<script>
		import Progress from '../../common/scripts/loading';
		import ChannelStream from '../../common/scripts/channel-stream';

		this.mixin('i');
		this.mixin('api');

		this.id = this.opts.id;
		this.fetching = true;
		this.postsFetching = true;
		this.channel = null;
		this.posts = null;
		this.connection = new ChannelStream(this.id);
		this.version = VERSION;

		this.on('mount', () => {
			document.documentElement.style.background = '#efefef';

			Progress.start();

			this.api('channels/show', {
				channel_id: this.id
			}).then(channel => {
				Progress.done();

				this.update({
					fetching: false,
					channel: channel
				});

				document.title = channel.title + ' | Misskey'
			});

			this.api('channels/posts', {
				channel_id: this.id
			}).then(posts => {
				this.update({
					postsFetching: false,
					posts: posts
				});
			});

			this.connection.on('post', this.onPost);
		});

		this.on('unmount', () => {
			this.connection.off('post', this.onPost);
			this.connection.close();
		});

		this.onPost = post => {
			this.posts.unshift(post);
			this.update();
		};

	</script>
</mk-channel>

<mk-channel-post>
	<header>
		<a class="index" onclick={ reply }>{ post.index }:</a>
		<a class="name" href={ '/' + post.user.username }><b>{ post.user.name }</b></a>
		<mk-time time={ post.created_at }/>
		<mk-time time={ post.created_at } mode="detail"/>
		<span>ID:<i>{ post.user.username }</i></span>
	</header>
	<div>
		<a if={ post.reply_to }>&gt;&gt;{ post.reply_to.index }</a>
		{ post.text }
		<div class="media" if={ post.media }>
			<virtual each={ file in post.media }>
				<img src={ file.url + '?thumbnail&size=512' } alt={ file.name } title={ file.name }/>
			</virtual>
		</div>
	</div>
	<style>
		:scope
			display block
			margin 0
			padding 0

			> header
				> .index
					margin-right 0.25em
					color #000

				> .name
					margin-right 0.5em
					color #008000

				> mk-time
					margin-right 0.5em

					&:first-of-type
						display none

				@media (max-width 600px)
					> mk-time
						&:first-of-type
							display initial

						&:last-of-type
							display none

			> div
				padding 0 0 1em 2em

	</style>
	<script>
		this.post = this.opts.post;
		this.form = this.opts.form;

		this.reply = () => {
			this.form.update({
				reply: this.post
			});
		};
	</script>
</mk-channel-post>

<mk-channel-form>
	<p if={ reply }><b>&gt;&gt;{ reply.index }</b> ({ reply.user.name }): <a onclick={ clearReply }>[x]</a></p>
	<textarea ref="text" disabled={ wait }></textarea>
	<button class={ wait: wait } ref="submit" disabled={ wait || (refs.text.value.length == 0) } onclick={ post }>
		{ wait ? 'やってます' : 'やる' }<mk-ellipsis if={ wait }/>
	</button>
	<br>
	<button onclick={ drive }>ドライブ</button>
	<ol if={ files }>
		<li each={ files }>{ name }</li>
	</ol>
	<style>
		:scope
			display block

	</style>
	<script>
		import CONFIG from '../../common/scripts/config';

		this.mixin('api');

		this.channel = this.opts.channel;

		this.clearReply = () => {
			this.update({
				reply: null
			});
		};

		this.clear = () => {
			this.clearReply();
			this.update({
				files: null
			});
			this.refs.text.value = '';
		};

		this.post = e => {
			this.update({
				wait: true
			});

			const files = this.files && this.files.length > 0
				? this.files.map(f => f.id)
				: undefined;

			this.api('posts/create', {
				text: this.refs.text.value,
				media_ids: files,
				reply_to_id: this.reply ? this.reply.id : undefined,
				channel_id: this.channel.id
			}).then(data => {
				this.clear();
			}).catch(err => {
				alert('失敗した');
			}).then(() => {
				this.update({
					wait: false
				});
			});
		};

		this.drive = () => {
			window['cb'] = files => {
				this.update({
					files: files
				});
			};
			window.open(CONFIG.url + '/selectdrive?multiple=true', '_blank');
		};
	</script>
</mk-channel-form>