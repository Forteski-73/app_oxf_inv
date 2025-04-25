import 'package:flutter/material.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:app_oxf_inv/styles/btnStyles.dart';

class PaginaComAcoesFlutuantes extends StatelessWidget {
  const PaginaComAcoesFlutuantes({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: '',
      subtitle: 'Painel de Ações',
      body: const Center(
        child: Text(
          'Conteúdo principal aqui\n'
          '1\n'
          '2\n'
          '3\n'
          '4\n'
          '...\nApp\n...\n...\n Oxford\n ...\n 123\n...\n...\n...\n..1.\n...\n...\n.2..\n...\n...texto \n...\n \n.3..\n...\n...\n...\n...\n...\n...\n...\nfim\n .'
          '(Conteúdo pode ser substituído)',
          textAlign: TextAlign.center,
        ),
      ),
      floatingButtons: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
          ),
          const SizedBox(height: 10),
          ButtonStyles.processButton(
            context,
            'Btn 100%',
            1, // tamanho 1 = 100%
            Icons.touch_app, // escolha o ícone que deseja exibir
            () {
              CustomSnackBar.show(
                context,
                message: 'Botão Grande',
                duration: const Duration(seconds: 2),
                type: SnackBarType.success,
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ButtonStyles.processButton(
                  context,
                  'Btn 50%',
                  2, // Tamanho 2 = 50%
                  Icons.touch_app, // ou outro ícone desejado
                  () {
                    CustomSnackBar.show(
                      context,
                      message: 'Botão Médio',
                      duration: const Duration(seconds: 2),
                      type: SnackBarType.warning,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10), // Espaço entre os botões
              Expanded(
                child: ButtonStyles.processButton(
                  context,
                  'Btn 50%',
                  2,
                  Icons.touch_app,
                  () {
                    CustomSnackBar.show(
                      context,
                      message: 'Botão Médio',
                      duration: const Duration(seconds: 2),
                      type: SnackBarType.info,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ButtonStyles.processButton(
                  context,
                  'Btn 25%',
                  3, // Tamanho 3 = 25%
                  null, // Ícone à sua escolha
                  () {
                    CustomSnackBar.show(
                      context,
                      message: 'Botão Pequeno',
                      duration: const Duration(seconds: 2),
                      type: SnackBarType.info,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ButtonStyles.processButton(
                  context,
                  'Btn 25%',
                  3,
                  null,
                  () {
                    CustomSnackBar.show(
                      context,
                      message: 'Botão Pequeno',
                      duration: const Duration(seconds: 2),
                      type: SnackBarType.info,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ButtonStyles.processButton(
                  context,
                  'Btn 25%',
                  3,
                  Icons.touch_app,
                  () {
                    CustomSnackBar.show(
                      context,
                      message: 'Botão Pequeno',
                      duration: const Duration(seconds: 2),
                      type: SnackBarType.info,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ButtonStyles.processButton(
                  context,
                  'Btn 25%',
                  3,
                  Icons.touch_app,
                  () {
                    CustomSnackBar.show(
                      context,
                      message: 'Botão Pequeno',
                      duration: const Duration(seconds: 2),
                      type: SnackBarType.info,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
