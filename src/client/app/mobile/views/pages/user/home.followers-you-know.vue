<template>
<div class="root followers-you-know">
	<p class="initializing" v-if="fetching">%fa:spinner .pulse .fw%%i18n:@loading%<mk-ellipsis/></p>
	<div v-if="!fetching && users.length > 0">
		<a v-for="user in users" :key="user.id" :href="user | userPage">
			<img :src="`${user.avatarUrl}?thumbnail&size=64`" :alt="user | userName"/>
		</a>
	</div>
	<p class="empty" v-if="!fetching && users.length == 0">%i18n:@no-users%</p>
</div>
</template>

<script lang="ts">
import Vue from 'vue';

export default Vue.extend({
	props: ['user'],
	data() {
		return {
			fetching: true,
			users: []
		};
	},
	mounted() {
		(this as any).api('users/followers', {
			userId: this.user.id,
			iknow: true,
			limit: 30
		}).then(res => {
			this.fetching = false;
			this.users = res.users;
		});
	}
});
</script>

<style lang="stylus" scoped>
.root.followers-you-know

	> div
		padding 4px

		> a
			display inline-block
			margin 4px

			> img
				width 48px
				height 48px
				vertical-align bottom
				border-radius 100%

	> .initializing
	> .empty
		margin 0
		padding 16px
		text-align center
		color #aaa

		> i
			margin-right 4px

</style>
