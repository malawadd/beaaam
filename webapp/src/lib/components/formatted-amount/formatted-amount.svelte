<script lang="ts">
  import formatTokenAmount from '$lib/utils/format-token-amount';
  import { constants } from 'beaaams-backend';

  export let amount = 0n;
  export let decimals = 16;
  export let multiplier = BigInt(constants.AMT_PER_SEC_MULTIPLIER);
</script>

<span>{formatTokenAmount(amount, decimals, multiplier)}</span>

<style>
  span {
    user-select: none;
  }
</style>
