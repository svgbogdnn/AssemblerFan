extern "C" void my_printf (const char*, ...);

int main () {
	my_printf ("Hello %c %s %x %d%%%c%b$", "I", "love$", 3802, 100, "!", 127);
	return 0;
}
