import 'package:flutter/material.dart';

import '../../core/adn_colors.dart';
import 'master_customer_registry.dart';

// ============================================================
// ADN PUBLICIDAD SOFTWARE MASTER
// SELECTOR COMPARTIDO DE CLIENTES
// ============================================================

class MasterCustomerSelector extends StatelessWidget {
  final ValueChanged<String?>? onChanged;

  const MasterCustomerSelector({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MasterCustomer>>(
      valueListenable: MasterCustomerRegistry.customers,
      builder: (context, customers, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cliente asociado *',
              style: TextStyle(
                color: AdnColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),

            if (customers.isEmpty)
              _emptyState()
            else
              _customerDropdown(customers),
          ],
        );
      },
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      decoration: BoxDecoration(
        color: AdnColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdnColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.business_outlined, color: AdnColors.muted, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sin clientes registrados',
              style: TextStyle(color: AdnColors.muted, fontSize: 12),
            ),
          ),
          Icon(Icons.lock_outline_rounded, color: AdnColors.muted, size: 18),
        ],
      ),
    );
  }

  Widget _customerDropdown(List<MasterCustomer> customers) {
    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );
    }

    return DropdownButtonFormField<String>(
      key: const Key('instance_customer'),
      isExpanded: true,
      dropdownColor: AdnColors.panel,
      initialValue: null,
      hint: const Text(
        'Seleccionar cliente registrado',
        style: TextStyle(color: AdnColors.muted, fontSize: 12),
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.business_outlined,
          color: AdnColors.turquoiseLight,
          size: 20,
        ),
        filled: true,
        fillColor: AdnColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: border(AdnColors.border),
        focusedBorder: border(AdnColors.turquoise),
        errorBorder: border(AdnColors.coral),
        focusedErrorBorder: border(AdnColors.coral),
      ),
      items: customers.map((customer) {
        return DropdownMenuItem<String>(
          value: customer.id,
          child: Text(
            customer.displayName,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AdnColors.white, fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: onChanged ?? (_) {},
    );
  }
}
