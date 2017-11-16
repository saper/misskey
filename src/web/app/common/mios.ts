import { EventEmitter } from 'eventemitter3';
import * as riot from 'riot';
import signout from './scripts/signout';
import Progress from './scripts/loading';
import Connection from './scripts/home-stream';
import CONFIG from './scripts/config';
import api from './scripts/api';

/**
 * Misskey Operating System
 */
export default class MiOS extends EventEmitter {
	/**
	 * Misskeyの /meta で取得できるメタ情報
	 */
	private meta: {
		data: { [x: string]: any };
		chachedAt: Date;
	};

	private isMetaFetching = false;

	/**
	 * A signing user
	 */
	public i: { [x: string]: any };

	/**
	 * Whether signed in
	 */
	public get isSignedin() {
		return this.i != null;
	}

	/**
	 * A connection of home stream
	 */
	public stream: Connection;

	constructor() {
		super();

		//#region BIND
		this.init = this.init.bind(this);
		this.api = this.api.bind(this);
		this.getMeta = this.getMeta.bind(this);
		//#endregion
	}

	/**
	 * Initialize MiOS (boot)
	 * @param callback A function that call when initialized
	 */
	public async init(callback) {
		// ユーザーをフェッチしてコールバックする
		const fetchme = (token, cb) => {
			let me = null;

			// Return when not signed in
			if (token == null) {
				return done();
			}

			// Fetch user
			fetch(`${CONFIG.apiUrl}/i`, {
				method: 'POST',
				body: JSON.stringify({
					i: token
				})
			}).then(res => { // When success
				// When failed to authenticate user
				if (res.status !== 200) {
					return signout();
				}

				res.json().then(i => {
					me = i;
					me.token = token;
					done();
				});
			}, () => { // When failure
				// Render the error screen
				document.body.innerHTML = '<mk-error />';
				riot.mount('*');
				Progress.done();
			});

			function done() {
				if (cb) cb(me);
			}
		};

		// フェッチが完了したとき
		const fetched = me => {
			if (me) {
				riot.observable(me);

				// この me オブジェクトを更新するメソッド
				me.update = data => {
					if (data) Object.assign(me, data);
					me.trigger('updated');
				};

				// ローカルストレージにキャッシュ
				localStorage.setItem('me', JSON.stringify(me));

				me.on('updated', () => {
					// キャッシュ更新
					localStorage.setItem('me', JSON.stringify(me));
				});
			}

			this.i = me;

			// Init home stream connection
			this.stream = this.i ? new Connection(this.i) : null;

			// Finish init
			callback();
		};

		// Get cached account data
		const cachedMe = JSON.parse(localStorage.getItem('me'));

		if (cachedMe) {
			fetched(cachedMe);

			// 後から新鮮なデータをフェッチ
			fetchme(cachedMe.token, freshData => {
				Object.assign(cachedMe, freshData);
				cachedMe.trigger('updated');
			});
		} else {
			// Get token from cookie
			const i = (document.cookie.match(/i=(!\w+)/) || [null, null])[1];

			fetchme(i, fetched);
		}
	}

	/**
	 * Misskey APIにリクエストします
	 * @param endpoint エンドポイント名
	 * @param data パラメータ
	 */
	public api(endpoint: string, data?: { [x: string]: any }) {
		return api(this.i, endpoint, data);
	}

	/**
	 * Misskeyのメタ情報を取得します
	 * @param force キャッシュを無視するか否か
	 */
	public getMeta(force = false) {
		return new Promise<{ [x: string]: any }>(async (res, rej) => {
			if (this.isMetaFetching) {
				this.once('_meta_fetched_', () => {
					res(this.meta.data);
				});
				return;
			}

			const expire = 1000 * 60; // 1min

			// forceが有効, meta情報を保持していない or 期限切れ
			if (force || this.meta == null || Date.now() - this.meta.chachedAt.getTime() > expire) {
				this.isMetaFetching = true;
				const meta = await this.api('meta');
				this.meta = {
					data: meta,
					chachedAt: new Date()
				};
				this.isMetaFetching = false;
				this.emit('_meta_fetched_');
				res(meta);
			} else {
				res(this.meta.data);
			}
		});
	}
}