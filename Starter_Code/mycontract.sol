// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SplitWise {
    struct IOU {
        address creditor;
        int32 amount;
        uint creditor_id;
        bool _valid;
    }
    struct Debtor {
        IOU [] IOUs; // list of IOU
        address debtor;
        uint id;
        bool _valid;
    }
    mapping (address => mapping(address => IOU)) ledger; // debtor and creditor map to IOU. better accessibility 
    mapping (address => Debtor) debtorMap; // faster access 
    Debtor[] ledgerArr; // debtors to array of creditors, return with less gas.
    
    function add_IOU(address _creditor, int32 _amount) public { // negative IOU is to resolve the loop
        require(msg.sender != _creditor, "One cannot owes to themself.");
        // * ignore case that ledger minus amount < 0 => error
        if (debtorMap[msg.sender]._valid == false){ // new user; index ledgerArr by map address to id in debtorMap
            IOU memory _IOU = IOU({creditor: _creditor, amount: _amount, creditor_id: 0, _valid: true});
            Debtor storage debtor = debtorMap[msg.sender]; // initialized with variable outside of the function is required, so that append is possible
            ledger[msg.sender][_creditor] = _IOU;
            debtor.IOUs.push(_IOU); // add an IOU in a debtor's IOU list
            debtor.debtor = msg.sender;
            debtor.id = ledgerArr.length;
            debtor._valid = true;
            ledgerArr.push(debtor);
            debtorMap[msg.sender] = debtor;
        }
        else if (ledger[msg.sender][_creditor]._valid == false) { // debtor's new creditor
            IOU memory _IOU = IOU({creditor: _creditor, amount: _amount, creditor_id: ledgerArr[debtorMap[msg.sender].id].IOUs.length, _valid: true});
            ledger[msg.sender][_creditor] = _IOU;
            ledgerArr[debtorMap[msg.sender].id].IOUs.push(_IOU);
        }
        else{ // update IOU
            require(ledger[msg.sender][_creditor].amount + _amount >= 0, "tx results to negative IOU.");
            ledger[msg.sender][_creditor].amount += _amount;
            ledgerArr[debtorMap[msg.sender].id].IOUs[ledger[msg.sender][_creditor].creditor_id].amount += _amount; 
            if (ledger[msg.sender][_creditor].amount == 0){
                ledger[msg.sender][_creditor]._valid = false;
                ledgerArr[debtorMap[msg.sender].id].IOUs[ledger[msg.sender][_creditor].creditor_id]._valid = false;
            } else {
                ledger[msg.sender][_creditor]._valid = true;
                ledgerArr[debtorMap[msg.sender].id].IOUs[ledger[msg.sender][_creditor].creditor_id]._valid = true;
            }
        }
    }

    function getLedger() public view returns(Debtor[] memory _ledgerArr){
        return ledgerArr;
    }
}