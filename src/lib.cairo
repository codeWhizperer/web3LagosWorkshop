use core::zeroable::Zeroable;
// use web3LagosWorkshop::IERC20;
use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowances(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn mint(ref self: TContractState, amount: u256);
}


#[starknet::contract]
mod ERC20 {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use option::OptionTrait;
    use integer::Zeroable;
    use integer::BoundedInt;


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        sender: ContractAddress,
        recipient: ContractAddress,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        amount: u256
    }

    #[storage]
    struct Storage {
        name: felt252,
        symbol: felt252,
        decimals: u8,
        total_supply: u256,
        balance: LegacyMap::<ContractAddress, u256>,
        allowance: LegacyMap::<(ContractAddress, ContractAddress), u256>
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252, decimals: u8) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.decimals.write(decimals);
    }

    impl IERC20Impl of super::IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }
        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }
        fn decimals(self: @ContractState) -> u8 {
            self.decimals.read()
        }
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balance.read(account)
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn mint(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            let prevBalance = self.balance.read(caller);
            let prevT = self.total_supply.read();
            self.balance.write(caller, prevBalance + amount);
            self.total_supply.write(prevT + amount);
            self
                .emit(
                    Event::Transfer(
                        Transfer { sender: Zeroable::zero(), recipient: caller, amount }
                    )
                );
        }

        fn allowances(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowance.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let caller = get_caller_address();
            self._spend_allowance(sender, caller, amount);
            self._transfer(caller, recipient, amount);
            true
        }
    }


    #[generate_trait]
    impl IERC20Internal of IERC20InternalTrait {
        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            assert(!sender.is_zero(), 'sender_is_zero');
            assert(!recipient.is_zero(), 'sender_is_zero');
            let prev_sender_balance = self.balance.read(sender);
            let prev_recipient_balance = self.balance.read(recipient);
            self.balance.write(sender, self.balance.read(sender) - amount);
            self.balance.write(recipient, self.balance.read(recipient) + amount);
            self.emit(Event::Transfer(Transfer { sender, recipient, amount }));
        }
        fn _approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!owner.is_zero(), 'ERC20: approve from 0');
            assert(!spender.is_zero(), 'ERC20: approve to 0');
            self.allowance.write((owner, spender), amount);
            self.emit(Event::Approval(Approval { owner, spender, amount }))
        }

        fn _spend_allowance(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            let current_allowance = self.allowance.read((owner, spender));
            if current_allowance != BoundedInt::max() {
                self._approve(owner, spender, current_allowance - amount);
            }
        }
        fn _increase_allowance(
            ref self: ContractState,
            owner: ContractAddress,
            spender: ContractAddress,
            amount_to_add: u256
        ) {
            let caller = get_caller_address();
            let current_allowance = self.allowance.read((owner, spender));
            self._approve(caller, spender, current_allowance + amount_to_add);
        }

        fn _decrease_allowance(
            ref self: ContractState,
            owner: ContractAddress,
            spender: ContractAddress,
            amount_to_sub: u256
        ) {
            let caller = get_caller_address();
            let current_allowance = self.allowance.read((owner, spender));
            self._approve(caller, spender, current_allowance - amount_to_sub);
        }
    }
}
// #[cfg(test)]
// mod test {
//     use core::result::ResultTrait;
// use web3lagosworkshop::IERC20SafeDispatcherTrait;
// use core::traits::TryInto;
//     use core::array::ArrayTrait;
//     use super::ERC20;
//     use snforge_std::{declare, ContractClassTrait};
//     use super::IERC20Dispatcher;
//     use super::IERC20DispatcherTrait;
//     use starknet::ContractAddress;
//     use super::IERC20SafeDispatcher;

//     const tokenName: felt252 = 'TestToken';
//     const decimals: felt252 = 18;
//     const symbol: felt252 = 'TTK';

//     // OZ 
//     mod Errors {
//         const INVALID_NAME: felt252 = 'Invalid name';
//         const INVALID_SYMBOL: felt252 = 'Invalid symbol';
//     }

//     fn setup(name:felt252) -> ContractAddress {
//         // declare contract
//         let contract = declare(name);
//         // deploy contract
//         let mut calldata = ArrayTrait::new();
//         calldata.append('TestToken');
//         calldata.append('TTK');
//         calldata.append(18);

//         let contract_address = contract.deploy(@calldata).unwrap();
//         // create a dispatcher object that will allow interacting with the deployed contract
//         contract_address
//     }

// #[test]
// fn test_token_name() {
//     let contract_address = setup('ERC20');
//     let dispatcher = IERC20SafeDispatcher {  contract_address };
//     let result_name = dispatcher.name().unwrap();
//     assert(result_name == 'TestToken', Errors::INVALID_NAME);
// }
// }


