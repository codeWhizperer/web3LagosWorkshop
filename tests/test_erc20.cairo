use web3lagosworkshop::IERC20;
use core::debug::PrintTrait;
// use snforge_std::forge_print::PrintTrait;
use core::result::ResultTrait;
use web3lagosworkshop::IERC20SafeDispatcherTrait;
use core::traits::TryInto;
use core::array::ArrayTrait;
use web3lagosworkshop::ERC20;
use snforge_std::{declare, ContractClassTrait};
use web3lagosworkshop::IERC20Dispatcher;
use web3lagosworkshop::IERC20DispatcherTrait;
use starknet::ContractAddress;
use web3lagosworkshop::IERC20SafeDispatcher;

const tokenName: felt252 = 'TestToken';
const decimals: u8 = 18;
const symbol: felt252 = 'TTK';

// OZ 
mod Errors {
    const INVALID_NAME: felt252 = 'Invalid name';
    const INVALID_SYMBOL: felt252 = 'Invalid symbol';
    const INVALID_DECIMAL:felt252 = 'Invalid decimal';
}

fn STATE() -> ERC20::ContractState{
    ERC20::contract_state_for_testing()
}

fn setup() -> ERC20::ContractState{
    let mut state = STATE();
    ERC20::constructor(ref state, tokenName, symbol, decimals);
    state
}

#[test]
fn test_constructor(){
    let mut state = setup();
    assert(state.name() == tokenName, Errors::INVALID_NAME);
    assert(state.symbol() == symbol, Errors::INVALID_SYMBOL);
    assert(state.decimals() == decimals, Errors::INVALID_DECIMAL);
}