using F1Info_Tickets.Services.Exceptions;
using Microsoft.AspNetCore.Http;

namespace F1Info_Tickets.Services.Helpers
{
    public static class FileHelper
    {
        public const long MaxImageBytes = 5 * 1024 * 1024;
        private const string ImageField = "Image";

        private static readonly byte[] JpegSignature = { 0xFF, 0xD8, 0xFF };
        private static readonly byte[] PngSignature = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };

        // The client's name, content type and size are only hints; the file content decides the format.
        public static async Task<string?> SaveImageAsync(
            IFormFile file,
            string folderName)
        {
            if (file == null || file.Length == 0)
                return null;

            if (file.Length > MaxImageBytes)
                throw new BusinessException(ImageField, "The image is too large. Upload an image up to 5 MB.");

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            var declaredPng = (extension == ".png") && (file.ContentType == "image/png");
            var declaredJpeg = (extension is ".jpg" or ".jpeg") && (file.ContentType is "image/jpeg" or "image/jpg");
            if (!declaredPng && !declaredJpeg)
                throw new BusinessException(ImageField, "Only JPG and PNG images are allowed.");

            var header = new byte[PngSignature.Length];
            int read;
            await using (var input = file.OpenReadStream())
                read = await input.ReadAtLeastAsync(header, header.Length, throwOnEndOfStream: false);
            var isPng = read >= PngSignature.Length && header.AsSpan(0, PngSignature.Length).SequenceEqual(PngSignature);
            var isJpeg = read >= JpegSignature.Length && header.AsSpan(0, JpegSignature.Length).SequenceEqual(JpegSignature);
            if ((declaredPng && !isPng) || (declaredJpeg && !isJpeg))
                throw new BusinessException(ImageField, "The file is not a valid JPG or PNG image.");

            var folderPath = Path.Combine(
                Directory.GetCurrentDirectory(),
                "wwwroot",
                "uploads",
                folderName
            );

            if (!Directory.Exists(folderPath))
                Directory.CreateDirectory(folderPath);

            var fileName = $"{Guid.NewGuid()}{(isPng ? ".png" : ".jpg")}";
            var filePath = Path.Combine(folderPath, fileName);

            await using var stream = new FileStream(filePath, FileMode.Create);
            await file.CopyToAsync(stream);

            return $"/images/{folderName}/{fileName}";
        }
    }
}
